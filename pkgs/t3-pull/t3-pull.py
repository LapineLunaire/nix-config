import argparse
import codecs
import ctypes
import glob
import io
import os
import pathlib
import re
import resource
import select
import shlex
import signal
import stat
import subprocess
import sys
import tempfile
import termios
import time

GIT = "@git@"
LESS = "@less@"
UPLOAD_PACK = "/etc/profiles/per-user/t3/bin/git-upload-pack"
NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._/-]*")
HOST = re.compile(r"[A-Za-z0-9][A-Za-z0-9.-]*")
PATH = re.compile(r"/[A-Za-z0-9._/-]+")
# These act later: Git hooks and the files of hook runners, CI workflows, .envrc when direnv enters its directory, the
# flake and its development shell, settings and instructions of coding agents and editors, .sops.yaml when secrets are
# encrypted, .lfsconfig, .gitattributes on how checkouts rewrite files and how diffs are shown, and .gitmodules on where
# submodules come from. RISKY holds top-level paths, RISKY_STARTS starts of paths, such as lefthook's many config file
# names, and RISKY_NAMES names of files or directories anywhere.
RISKY = {b".githooks", b".husky", b".pre-commit-config.yaml", b".forgejo", b".gitea", b".github", b"flake.nix", b"flake.lock", b".codex", b".mcp.json", b".vscode", b".zed", b".lfsconfig", b".gitmodules"}
RISKY_STARTS = (b"lefthook", b".lefthook", b".config/lefthook")
RISKY_NAMES = {b".envrc", b".sops.yaml", b".agents", b".claude", b"AGENTS.md", b"AGENTS.override.md", b"CLAUDE.md", b"CLAUDE.local.md", b".gitattributes"}
# SOPS metadata keys in YAML, JSON, dotenv, and INI files, and the ciphertext SOPS writes. Escapes in YAML or JSON can
# still hide both.
SOPS = r"""ENC\[AES256_GCM,|^["']?sops["']?[[:space:]]*:|"sops"[[:space:]]*:|^sops_mac=|^\[sops\]"""
# Default_Ignorable_Code_Point characters that isprintable() accepts, such as variation selectors, and the blank
# Braille pattern, which looks like a space.
IGNORABLE = re.compile(r"[\u034f\u115f\u1160\u17b4\u17b5\u180b-\u180f\u2800\u3164\ufe00-\ufe0f\uffa0\U000e0100-\U000e01ef]")
PR_SET_CHILD_SUBREAPER = 36
# Diffs show every file as text and every submodule, whatever the agent's attributes or the user's diff settings say.
# Without renames, a file moved somewhere it acts, such as into the hooks, shows in full.
DIFF = ["--no-color", "--no-ext-diff", "--no-textconv", "--text", "--ignore-submodules=none", "--submodule=short", "--no-renames"]
# More would be too much to review, and escapes make hostile data up to six times as long when shown.
REVIEW_LIMIT = 16 << 20

codecs.register_error("t3-pull", lambda error: ("".join(f"\\x{{{byte:02X}}}" for byte in error.object[error.start:error.end]), error.end))


def hidden(char):
    return char not in "\t\n" and (not char.isprintable() or IGNORABLE.match(char))


def visible_text(text):
    """Shows control, invisible, and invalid characters, and spaces other than the plain one, as \\x{..} escapes."""
    # Most text is printable, which isprintable() checks quickly for the whole string.
    if text.replace("\t", "").replace("\n", "").isprintable() and not IGNORABLE.search(text):
        return text
    return "".join(f"\\x{{{ord(char):X}}}" if hidden(char) else char for char in text)


class Visible:
    """Writes agent output through visible_text.

    With crlf, a carriage return right before a newline is dropped: SSH ends its messages that way, and there it cannot
    move the cursor over other text. Diffs keep theirs, where it is part of a file.
    """

    def __init__(self, out, crlf=False):
        self.decoder = codecs.getincrementaldecoder("utf-8")("t3-pull")
        self.out = out
        self.crlf = crlf
        self.held = ""

    def write(self, data, final=False):
        text = self.decoder.decode(data, final)
        if self.crlf:
            # A carriage return at the end waits for the next block, which may start with the newline.
            text = self.held + text
            self.held = "\r" if text.endswith("\r") and not final else ""
            text = text[:len(text) - len(self.held)].replace("\r\n", "\n")
        self.out.write(visible_text(text).encode())
        self.out.flush()


def die(message, err=b""):
    Visible(sys.stderr.buffer, crlf=True).write(err + f"t3-pull: {message}\n".encode(), final=True)
    sys.exit(1)


def lines(paths):
    """Joins paths into lines. visible_text leaves tabs and newlines alone, so they are escaped here."""
    return b"".join(path.replace(b"\t", b"\\x{9}").replace(b"\n", b"\\x{A}") + b"\n" for path in paths)


def limit_resources():
    # The t3 side can send endless data, or objects that expand to huge sizes.
    for kind, value in [(resource.RLIMIT_AS, 4 << 30), (resource.RLIMIT_CPU, 600), (resource.RLIMIT_FSIZE, 1 << 30)]:
        resource.setrlimit(kind, (value, value))


def git_command(*args):
    # Smaller pack windows keep Git's memory maps within the address space limit. Background maintenance would be killed
    # with its lock held, and an fsmonitor daemon would keep the limits. Renormalizing would run filters on the agent's
    # files while merging, before the review.
    return [GIT, "-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null", "-c", "core.packedGitLimit=1g", "-c", "core.packedGitWindowSize=64m", "-c", "maintenance.auto=false", "-c", "merge.renormalize=false", *args]


def stop(proc):
    if proc.poll() is None:
        proc.kill()
    proc.wait()
    for pipe in (proc.stdout, proc.stderr):
        if pipe:
            pipe.close()
    # Descendants such as SSH can outlive Git. During the agent fetch, t3-pull is their subreaper, so they become its
    # children, and reaping one can hand over its own descendants.
    while pids := [int(pid) for path in glob.glob("/proc/self/task/*/children") for pid in open(path).read().split()]:
        for pid in pids:
            try:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)
            except (ProcessLookupError, ChildProcessError):
                pass


def run(label, command, show=False, timeout=None, limit=16 << 20, limited=True, env=None, overflow=None):
    """Runs command and returns its status, stdout, and stderr.

    With show, its output goes through Visible to stderr. With show="stderr", only its stderr does, and stdout is returned.
    """
    merged = show is True
    proc = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT if merged else subprocess.PIPE, env=env, preexec_fn=limit_resources if limited else None)
    pipes = [proc.stdout] if merged else [proc.stdout, proc.stderr]
    live = pipes[-1] if show else None
    data = {pipe: bytearray() for pipe in pipes}
    shown = Visible(sys.stderr.buffer, crlf=True)
    deadline = timeout and time.monotonic() + timeout
    total = 0
    try:
        while pipes:
            wait = deadline and deadline - time.monotonic()
            if deadline and wait <= 0:
                die(f"{label} took longer than {timeout} seconds")
            for pipe in select.select(pipes, [], [], wait)[0]:
                block = os.read(pipe.fileno(), 65536)
                total += len(block)
                if not block:
                    pipes.remove(pipe)
                elif total > limit:
                    die(overflow or f"{label} wrote more than {limit} bytes")
                elif pipe is live:
                    shown.write(block)
                else:
                    data[pipe] += block
        shown.write(b"", final=True)
        try:
            proc.wait(deadline and max(deadline - time.monotonic(), 0))
        except subprocess.TimeoutExpired:
            die(f"{label} took longer than {timeout} seconds")
    finally:
        stop(proc)
    return proc.returncode, bytes(data[proc.stdout]), bytes(data.get(proc.stderr, b""))


def git(*args, check=True):
    status, out, err = run(f"git {args[0]}", git_command(*args))
    if check and status:
        die(f"git {args[0]} failed", err)
    return subprocess.CompletedProcess(args, status, out, err)


def output(*args, check=True):
    return git(*args, check=check).stdout.decode("utf-8", "t3-pull").strip()


def checked_out():
    return output("symbolic-ref", "--quiet", "--short", "HEAD", check=False)


def dirty():
    return git("diff", "--quiet", check=False).returncode or git("diff", "--cached", "--quiet", check=False).returncode


def show_diff(base, tree):
    """Shows the diff and returns whether it escaped anything."""
    too_large = f"the diff is over {REVIEW_LIMIT >> 20} MiB when shown, which is too much to review; ask the agent for a smaller change. Nothing changed."
    status, out, err = run("git diff", git_command("diff", *DIFF, base, tree), limit=REVIEW_LIMIT, overflow=too_large)
    if status:
        die("showing the diff failed; nothing changed", err)
    # Escaping in blocks keeps memory use near the limit.
    text = io.BytesIO()
    shown = Visible(text)
    for at in range(0, len(out), 65536):
        shown.write(out[at:at + 65536], at + 65536 >= len(out))
        if text.tell() > REVIEW_LIMIT:
            die(too_large)
    # The user's pager could act on the agent's text: nvimpager, for one, follows Vim modelines unless Git started it.
    # LESSSECURE turns off LESSOPEN, lesskey files, and commands that run programs or write files, and other LESS
    # variables such as LESSSECURE_ALLOW could turn them back on. Without a terminal, less copies the text. With K, less
    # quits on Ctrl-C and restores the terminal, as it does on SIGTERM, which t3-pull passes on when it stops otherwise.
    env = {key: value for key, value in os.environ.items() if not key.startswith("LESS")}
    proc = subprocess.Popen([LESS], stdin=subprocess.PIPE, env={**env, "LESS": "FKX", "LESSSECURE": "1"})
    try:
        # communicate() ignores a pager that quits before reading everything.
        proc.communicate(text.getvalue())
    except BaseException:
        proc.terminate()
        raise
    finally:
        proc.wait()
    if proc.returncode:
        die("the pager failed; nothing changed")
    # Escapes only ever make the text longer.
    return text.tell() != len(out)


def landing(raw):
    """Returns the header lines and the message of a raw commit."""
    head, _, message = raw.partition(b"\n\n")
    return head.split(b"\n"), message


def merge(parent, base, commit, upstream):
    """Returns the tree that applying commit to base, the tip of upstream, gives, without touching the work tree."""
    status, out, err = run("git merge-tree", git_command("merge-tree", "--write-tree", "-z", "--name-only", "--no-messages", f"--merge-base={parent}", base, commit))
    tree, *conflicts = out.split(b"\0")
    if status not in (0, 1):
        die("git merge-tree failed", err)
    if status:
        die(f"the commit conflicts with {upstream} in these files; ask the agent to rebase it onto {upstream}. Nothing changed.\n" + lines(sorted(set(filter(None, conflicts)))).decode("utf-8", "t3-pull").removesuffix("\n"))
    return tree.decode()


def changes(base, tree):
    """Returns the changed paths with their old and new modes."""
    raw = git("diff", *DIFF, "--raw", "-z", base, tree).stdout.split(b"\0")
    return {path: set(info[1:].split(b" ")[:2]) for info, path in zip(raw[::2], raw[1::2])}


def configured_paths():
    """Returns the paths in the work tree that the user's Git config takes hooks or more config from, b"" for its top."""
    # git_command() points core.hooksPath at /dev/null, so this asks Git without it.
    status, hooks, err = run("git rev-parse", [GIT, "rev-parse", "--git-path", "hooks"])
    if status:
        die("git rev-parse failed", err)
    paths = [os.fsdecode(hooks).removesuffix("\n")]
    found = git("config", "-z", "--show-origin", "--get-regexp", r"^include(if\..*)?\.path$", check=False).stdout.split(b"\0")
    for origin, entry in zip(found[::2], found[1::2]):
        # Git reads a relative include path from the directory of the file that has it.
        paths.append(os.path.join(os.path.dirname(os.fsdecode(origin).removeprefix("file:")), os.path.expanduser(os.fsdecode(entry.partition(b"\n")[2]))))
    # The path with each of its ancestors resolved in turn: the work tree may be reached through a symlink, and the
    # agent's commit can replace a symlink inside it with a directory. Joining keeps ".." where it is, since a symlink
    # before it changes where it leads.
    found = set()
    for path in (os.path.join(os.getcwd(), path) for path in paths):
        for head in [path, *map(str, pathlib.PurePath(path).parents)]:
            found.add(os.path.relpath(os.path.join(os.path.realpath(head), os.path.relpath(path, head))))
    return {b"" if path == "." else os.fsencode(path) for path in found if path != ".." and not path.startswith(("../", ".git/"))}


def risky_files(changed, configured):
    # Git runs hooks from files directly in the hooks directory, which the dirname test covers when that is the top of the
    # work tree. Symlinks can redirect any of the risky paths or their parents. Submodules fetch other repositories.
    def risky(path, modes):
        parts = path.split(b"/")
        under = any(path == top or path.startswith(top + b"/") or os.path.dirname(path) == top for top in configured)
        return under or parts[0] in RISKY or path.startswith(RISKY_STARTS) or RISKY_NAMES & set(parts) or {b"120000", b"160000"} & modes

    return sorted(path for path, modes in changed.items() if risky(path, modes))


def in_the_way(changed):
    """Returns the untracked and ignored paths, with a / after directories, that checking out the commit would overwrite or delete."""
    # Git treats ignored files as expendable. Keep folded directories to avoid listing all their files, and inspect
    # only the paths the commit needs below them. lstat keeps symlinks from passing as directories.
    found = git("ls-files", "-z", "--others", "--directory").stdout.split(b"\0")
    blocking = set()
    for other in filter(None, found):
        top = other.rstrip(b"/")
        for path in changed:
            if top == path or top.startswith(path + b"/"):
                blocking.add(other)
            elif path.startswith(top + b"/"):
                parts = path[len(top) + 1:].split(b"/")
                candidate = top
                for part in [None, *parts]:
                    if part is not None:
                        candidate += b"/" + part
                    try:
                        directory = stat.S_ISDIR(os.lstat(candidate).st_mode)
                    except FileNotFoundError:
                        break
                    if not directory or candidate == path:
                        blocking.add(candidate + (b"/" if directory else b""))
                        break
    return sorted(blocking)


def encrypted_files(base, tree, changed):
    # Anyone can encrypt a SOPS file to the public keys in .sops.yaml, and its diff shows only ciphertext.
    names = set()
    for rev in (base, tree):
        status, out, err = run("git grep", git_command("grep", "--no-color", "-l", "-z", "--text", "-E", SOPS, rev))
        if status not in (0, 1):
            die("git grep failed", err)
        names |= {name.removeprefix(f"{rev}:".encode()) for name in out.split(b"\0") if name}
    return sorted(names & changed.keys())


def fetch_agent(command, ssh):
    """Runs the fetch from the t3 side and returns whether it worked."""
    # t3-pull is the subreaper of this fetch only, so that stop() also ends what SSH leaves behind. The user's own
    # commands can leave agents such as gpg-agent or an SSH control master that should keep running.
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(PR_SET_CHILD_SUBREAPER, 1):
        die("cannot become a subreaper, which t3-pull needs to stop SSH and its descendants")
    # Git keeps a fetched pack with a .keep file until the fetch ends, and a fetch the t3 side stalls ends only when
    # t3-pull stops it. The .keep would then protect the pack from gc for good.
    packs = glob.escape(output("rev-parse", "--git-path", "objects/pack"))
    kept = set(glob.glob(f"{packs}/*.keep"))
    fetched = False
    try:
        # GIT_SSH_COMMAND overrides core.sshCommand, so an inherited one would replace this command.
        fetched = not run("git fetch", command, show=True, timeout=600, limit=1 << 20, env={**os.environ, "GIT_SSH_COMMAND": ssh})[0]
        return fetched
    finally:
        libc.prctl(PR_SET_CHILD_SUBREAPER, 0)
        if not fetched:
            for path in set(glob.glob(f"{packs}/*.keep")) - kept:
                with open(path, "rb") as keep:
                    if keep.read().startswith(b"fetch-pack "):
                        os.remove(path)


class Parser(argparse.ArgumentParser):
    def error(self, message):
        die(f"{message}\n{self.format_usage().strip()}")


def main():
    # SIGTERM and SIGHUP, such as from closing the terminal, stop t3-pull through the same cleanup as errors.
    for number, code in [(signal.SIGTERM, 143), (signal.SIGHUP, 129)]:
        signal.signal(number, lambda *_, code=code: sys.exit(code))
    if not glob.glob("/proc/self/task/*/children"):
        die("t3-pull needs Linux with /proc/<pid>/task/<tid>/children, to find what SSH leaves behind")
    parser = Parser(prog="t3-pull", description="Pulls one commit from a branch in the t3 user's clone, shows it, and lands it as a commit that you author and sign.")
    parser.add_argument("--check", action="store_true", help="run nix fmt -- --check and nix flake check afterwards")
    parser.add_argument("--host", help="pull from the t3 user on another host")
    parser.add_argument("--onto", metavar="BRANCH", help="land on this branch, which must be checked out, instead of the default branch, such as a pull request's branch")
    parser.add_argument("branch")
    parser.add_argument("source", nargs="?", metavar="t3 repository path")
    args = parser.parse_args()
    branch, host, onto = args.branch, args.host, args.onto
    if not NAME.fullmatch(branch) or git("check-ref-format", "--branch", branch, check=False).returncode:
        die(f"not a branch name: {branch}")
    if host is not None and not HOST.fullmatch(host):
        die(f"not a host name: {host}")
    os.chdir(output("rev-parse", "--show-toplevel"))
    source = args.source or f"/var/lib/t3/{os.path.basename(os.getcwd())}"
    if not PATH.fullmatch(source):
        die(f"not a repository path: {source}")
    where = host or "this host"

    current = checked_out()
    if not current:
        die("no branch is checked out; switch to the branch the commit is for with git switch <branch>")
    # The branch is never inferred: a commit lands on a branch other than the default one only when --onto names it, and
    # only while it is checked out, so being on another branch than expected cannot send a commit to the wrong place.
    if onto is not None and onto != current:
        die(f"--onto names {onto}, but {current} is checked out; run git switch {onto} and then t3-pull again")
    upstream_result = git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}", check=False)
    upstream = "" if upstream_result.returncode else upstream_result.stdout.decode("utf-8", "t3-pull").strip()
    remote = output("config", f"branch.{current}.remote", check=False)
    if not upstream or not remote:
        die(f"{current} has no upstream branch; push it with git push --set-upstream <remote> {current}, or set one with git branch --set-upstream-to=<remote>/<branch>")
    if dirty():
        die("the work tree has changes; commit or stash them first")
    # Merge drivers would run on the agent's files while merging, before the review. Hooks set in Git config ignore
    # core.hooksPath, and would run while fetching and landing the commit. fetch.fsck settings would let malformed objects
    # through the fetch. fetch.uriProtocols and promisor.acceptFromServer would let the t3 side send Git to other URLs,
    # and promisor.acceptFromServer add remotes to the user's config.
    if unsafe := output("config", "--name-only", "--get-regexp", r"^(merge\..*\.driver|hook\..*\.command|fetch\.fsck\..*|fetch\.uriprotocols|promisor\.acceptfromserver(url)?)$", check=False):
        die(f"t3-pull does not run while Git config sets merge drivers, hooks, fetch.fsck, fetch.uriProtocols, or promisor.acceptFromServer; git config --show-origin --get-regexp <name> shows where each of these is set, to unset it:\n{unsafe}")
    # followRemoteHEAD updates the remote's HEAD in the same fetch, in case the default branch changed. This fetch and the
    # fast-forward only read the user's own repository and remote, and can leave agents such as an SSH control master or
    # a credential cache, which should not keep t3-pull's limits.
    if run("git fetch", git_command("-c", f"remote.{remote}.followRemoteHEAD=always", "fetch", "--quiet", remote), show=True, limited=False)[0]:
        die(f"cannot fetch {remote}; fix what Git reports above and run t3-pull again")
    default_result = git("rev-parse", "--abbrev-ref", f"{remote}/HEAD", check=False)
    default = "" if default_result.returncode else default_result.stdout.decode("utf-8", "t3-pull").strip()
    if onto is None and upstream != default:
        again = shlex.join(["t3-pull", *(["--check"] if args.check else []), *(["--host", host] if host else []), "--onto", current, branch, *([args.source] if args.source else [])])
        die(f"{current} tracks {upstream}, not the default branch {default or 'of ' + remote}. If the commit is for {current}, such as a follow-up on its pull request, name the branch: {again}. Otherwise switch to the default branch first.")
    # The upstream branch can move while agents work, so a branch that is only behind is fast-forwarded.
    base = output("rev-parse", upstream)
    if output("rev-parse", "HEAD") != base:
        if git("merge-base", "--is-ancestor", "HEAD", base, check=False).returncode:
            die(f"{current} has commits that {upstream} lacks; push them, or drop them with git reset --keep {upstream}, first")
        if run("git merge", git_command("merge", "--ff-only", "--quiet", base), show=True, limited=False)[0]:
            die(f"cannot fast-forward {current} to {upstream}; fix what Git reports above and run t3-pull again")

    ref = f"refs/t3-pull/{branch}"
    with tempfile.NamedTemporaryFile("w", prefix="t3-pull-") as known:
        try:
            # Everything on the t3 side, including upload-pack, runs as t3 and is under the agent's control. On this host,
            # the host key is pinned to the one in /etc/ssh. Another host must already be in the user's known hosts.
            ssh = "ssh -o StrictHostKeyChecking=yes -o ForwardAgent=no -o ForwardX11=no -o ClearAllForwardings=yes -o PermitLocalCommand=no -o ControlMaster=no -o ControlPath=none -o GSSAPIDelegateCredentials=no"
            if host is None:
                for name in os.listdir("/etc/ssh"):
                    if re.fullmatch(r"ssh_host_.*_key\.pub", name):
                        with open(f"/etc/ssh/{name}") as key:
                            known.write("127.0.0.1 " + " ".join(key.read().split()[:2]) + "\n")
                known.flush()
                ssh += f" -o UserKnownHostsFile={shlex.quote(known.name)} -o GlobalKnownHostsFile=/dev/null -o CanonicalizeHostname=no"
            print(f"Fetching {branch} from {source} on {where}.", file=sys.stderr)
            # fsck refuses malformed objects, such as trees with one path twice, whose diff would differ from what lands.
            # Keeping the pack as it arrives stops small deltas from expanding into many huge loose objects on disk.
            fetch = git_command("-c", "fetch.fsckObjects=true", "-c", "fetch.unpackLimit=1", "fetch", "--quiet", "--no-tags", "--no-recurse-submodules", "--no-write-fetch-head", f"--upload-pack={UPLOAD_PACK}", f"ssh://t3@{host or '127.0.0.1'}{source}", f"+refs/heads/{branch}:{ref}")
            if not fetch_agent(fetch, ssh):
                die(f"cannot fetch {branch} from {source} on {where}; check the branch, the repository path, and the host against the agent's report, and pass the path after the branch or the host with --host if they differ")
            commit = output("rev-parse", "--verify", f"{ref}^{{commit}}")
            # The message lands as it is, while Git settings such as the log encoding change what log shows. An encoding
            # header would make the bytes mean other characters than they do as UTF-8.
            raw = git("cat-file", "commit", commit).stdout
            headers, message = landing(raw)
            if len(raw) > 65536:
                die(f"{branch} has a commit over 64 KiB; ask the agent to shorten its message")
            if visible_text(raw.decode("utf-8", "t3-pull")).encode() != raw:
                die(f"{branch} has control characters, invalid UTF-8, invisible characters, or spaces other than the plain space in its message or headers; ask the agent to reword the commit")
            if any(line.startswith(b"encoding ") for line in headers):
                die(f"{branch} has an encoding header; ask the agent to commit in UTF-8 without one")
            if not message.split(b"\n", 1)[0].strip():
                die(f"{branch} has an empty message or one that starts with a blank line; ask the agent to reword the commit")

            # One commit with one parent from the history of the upstream branch, which is the default branch unless
            # --onto names another. The tree it gives on the reviewed base is computed first, so what is shown is the
            # tree that lands, even when the upstream branch moved.
            parents = output("rev-list", "--parents", "-n", "1", commit).split()
            if len(parents) != 2:
                die(f"{branch} must be one commit with one parent; ask the agent to squash it")
            parent = parents[1]
            if git("merge-base", "--is-ancestor", parent, base, check=False).returncode:
                other = f"switch to the branch it is for and run t3-pull --onto <that branch> {branch}" if onto is None else "run t3-pull from the branch it is for"
                die(f"{branch} must be one commit on a commit of {upstream}, and its parent {parent} is not one. If it is for {current}, ask the agent to rebase it onto {upstream}; if it is for another branch, {other}.")
            tree = merge(parent, base, commit, upstream)
            if tree == output("rev-parse", f"{base}^{{tree}}"):
                die(f"{branch} changes nothing on {upstream}. If you expected a change, check that the commit is the one the agent reported, and tell the agent that {upstream} already has it.")
            changed = changes(base, tree)
            if blocking := in_the_way(changed):
                die("files that Git does not track, some perhaps ignored, are where the commit puts its files; move them first. Nothing changed.\n" + lines(blocking).decode("utf-8", "t3-pull").removesuffix("\n"))

            escaped = show_diff(base, tree)
            shown = Visible(sys.stdout.buffer)
            shown.write(git("log", "-1", "--no-color", "--no-decorate", "--no-show-signature", "--no-abbrev-commit", "--encoding=UTF-8", "--format=commit %H%n%n%w(0,4,4)%B", commit).stdout + b"\n")
            shown.write(git("diff", "--stat", *DIFF, base, tree).stdout)
            if risky := risky_files(changed, configured_paths()):
                shown.write(b"\nThis commit changes files that act later:\n" + lines(risky))
            if encrypted := encrypted_files(base, tree, changed):
                shown.write(b"\nThis commit changes encrypted files, whose diff shows only ciphertext:\n" + lines(encrypted))
            if escaped:
                shown.write(b"\nThe diff has control, invisible, or invalid characters, shown as \\x{..} escapes.\n")
            shown.write(b"", final=True)
            if moved := int(output("rev-list", "--count", f"{parent}..{base}")):
                print(f"\n{upstream} moved {moved} commit{'s' * (moved != 1)} past the agent's commit. What is shown is what lands on it.", file=sys.stderr)
            if sys.stdin.isatty():
                termios.tcflush(sys.stdin.fileno(), termios.TCIFLUSH)
            print(f"Pull {commit} from {branch} onto {current} and sign it? [y/N] ", end="", file=sys.stderr, flush=True)
            if sys.stdin.readline().strip() != "y":
                die("not confirmed; nothing changed")
        finally:
            # This runs before the commit lands: once the agent's files are checked out, a file that the user's Git config
            # includes can add hooks to the Git commands that follow.
            git("update-ref", "-d", ref)

    # The review holds only for the branch, base, and untracked files it was computed with.
    def unchanged():
        return checked_out() == current and output("rev-parse", "HEAD") == base and not dirty() and not in_the_way(changed)

    if not unchanged():
        die(f"{current} or its untracked files changed during the review; nothing changed. Run t3-pull again.")
    # commit-tree makes the commit with the user's Git identity as author and committer, and takes the message as it is.
    # The user's commit encoding would otherwise add an encoding header. Nothing has changed yet if signing fails, and agents that signing starts
    # should not keep the limits.
    with tempfile.NamedTemporaryFile(prefix="t3-pull-") as text:
        text.write(message)
        text.flush()
        status, out, _ = run("git commit-tree", git_command("-c", "i18n.commitEncoding=UTF-8", "commit-tree", "-S", "-p", base, "-F", text.name, tree), show="stderr", limited=False)
    signed = out.decode().strip()
    if status or not signed:
        die("cannot make the signed commit; nothing changed. Check that your signing key is available and run t3-pull again.")
    made, landed = landing(git("cat-file", "commit", signed).stdout)
    if made[:2] != [f"tree {tree}".encode(), f"parent {base}".encode()] or any(line.startswith(b"encoding ") for line in made) or landed != message:
        die("the signed commit does not hold the reviewed tree and message; nothing changed")
    # Signing can wait a long time, such as for a YubiKey touch.
    if not unchanged():
        die(f"{current} or its untracked files changed during the signing; nothing changed. Run t3-pull again.")
    # merge-tree already did the merge within the limits, so this only checks the tree out.
    checked = None
    try:
        if not run("git merge", git_command("merge", "--ff-only", "--quiet", signed), show=True, limited=False)[0]:
            checked = checked_out() == current and output("rev-parse", "HEAD") == signed
    finally:
        # A failure or a stop, such as Ctrl-C, can come before or after the branch moves.
        if checked is None:
            print(f"t3-pull: the fast-forward to {signed} or its check did not finish; check HEAD and git status, and undo it with git reset --keep {base}", file=sys.stderr)
    if checked is None:
        sys.exit(1)
    if not checked:
        die(f"HEAD is not the signed commit {signed}; undo it with git reset --keep {base}")

    if args.check:
        checks = [
            ["nix", "fmt", "--no-write-lock-file", "--", "--check", "."],
            ["nix", "flake", "check", "--all-systems", "--no-build", "--no-write-lock-file", "--option", "allow-import-from-derivation", "false"],
        ]
        if any(run(" ".join(check[:2]), check, show=True, limit=1 << 30, limited=False)[0] for check in checks):
            die(f"the checks failed; fix them, or undo the commit with git reset --keep {base}")
    print(f"Signed {output('rev-parse', '--short', 'HEAD')}. Push it with git push.", file=sys.stderr)


try:
    main()
except KeyboardInterrupt:
    sys.exit(130)
except Exception as error:
    # Messages can quote agent data, so they go through Visible too.
    die(f"{type(error).__name__}: {error}")
