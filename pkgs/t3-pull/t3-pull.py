import argparse
import codecs
import ctypes
import glob
import os
import re
import resource
import select
import signal
import subprocess
import sys
import tempfile
import time
import unicodedata

GIT = "@git@"
UPLOAD_PACK = "/etc/profiles/per-user/t3/bin/git-upload-pack"
NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._/-]*")
HOST = re.compile(r"[A-Za-z0-9][A-Za-z0-9.-]*")
PATH = re.compile(r"/[A-Za-z0-9._/-]+")
# These act later: hooks on the next commit, workflows on the runner, .envrc with the flake's development shell, which
# also sets core.hooksPath to .githooks, settings and instructions of coding agents and editors, .sops.yaml when secrets
# are encrypted, and .gitattributes on how later diffs are shown.
RISKY = [".githooks", ".forgejo", ".envrc", "flake.nix", "flake.lock", ".sops.yaml", ".claude", ".codex", ".mcp.json", ".zed", "*AGENTS.md", "*CLAUDE.md", "*.gitattributes"]
# SOPS metadata keys in YAML, JSON, dotenv, and INI files, and the ciphertext SOPS writes. Escapes in YAML or JSON can
# still hide both.
SOPS = r"""ENC\[AES256_GCM,|^["']?sops["']?[[:space:]]*:|"sops"[[:space:]]*:|^sops_mac=|^\[sops\]"""
HIDDEN_CATEGORIES = {"Cc", "Cf", "Cs", "Co", "Cn", "Zl", "Zp"}
# Default_Ignorable_Code_Point characters that are not in HIDDEN_CATEGORIES, such as variation selectors.
IGNORABLE = re.compile(r"[\u034f\u115f\u1160\u17b4\u17b5\u180b-\u180f\u3164\ufe00-\ufe0f\uffa0\U000e0100-\U000e01ef]")
SAFE = re.compile(r"[\t\n]")
PR_SET_CHILD_SUBREAPER = 36
# Diffs of agent changes show every file as text, without programs or attributes from the agent changing the output.
DIFF = ["--no-color", "--no-ext-diff", "--no-textconv", "--text"]


def escape_bytes(error):
    bad = error.object[error.start:error.end]
    return "".join(f"\\x{{{byte:02X}}}" for byte in bad), error.end


codecs.register_error("t3-pull", escape_bytes)


def escape(char):
    hidden = unicodedata.category(char) in HIDDEN_CATEGORIES or IGNORABLE.match(char)
    return f"\\x{{{ord(char):X}}}" if hidden and char not in "\t\n" else char


def visible_text(text):
    # isprintable() is False for every hidden category, so most text skips the loop.
    if SAFE.sub("", text).isprintable() and not IGNORABLE.search(text):
        return text
    return "".join(map(escape, text))


class Visible:
    """Writes agent output with control, invisible, and invalid characters shown as \\x{..} escapes."""

    def __init__(self, out):
        self.decoder = codecs.getincrementaldecoder("utf-8")("t3-pull")
        self.out = out

    def write(self, data, final=False):
        self.out.write(visible_text(self.decoder.decode(data, final)).encode())
        self.out.flush()


def die(message):
    Visible(sys.stderr.buffer).write(f"t3-pull: {message}\n".encode(), final=True)
    sys.exit(1)


def limit_resources():
    # The t3 side can send endless data, or objects that expand to huge sizes.
    for kind, value in [(resource.RLIMIT_AS, 4 << 30), (resource.RLIMIT_CPU, 600), (resource.RLIMIT_FSIZE, 1 << 30)]:
        resource.setrlimit(kind, (value, value))


def git_command(*args):
    # Smaller pack windows keep Git's memory maps within the address space limit. Background maintenance would become a
    # child of t3-pull, and stop() would kill it and leave its lock behind.
    return [GIT, "-c", "core.hooksPath=/dev/null", "-c", "core.packedGitLimit=1g", "-c", "core.packedGitWindowSize=64m", "-c", "maintenance.auto=false", *args]


def start(command, stderr, limited=True, env=None, stdin=subprocess.DEVNULL):
    return subprocess.Popen(command, stdin=stdin, stdout=subprocess.PIPE, stderr=stderr, env=env, preexec_fn=limit_resources if limited else None)


def stop(proc):
    if proc.poll() is None:
        proc.kill()
    proc.wait()
    for pipe in (proc.stdout, proc.stderr):
        if pipe:
            pipe.close()
    # Descendants such as SSH can outlive Git. t3-pull is their subreaper, so they become its children, and reaping one
    # can hand over its own descendants.
    while pids := [int(pid) for path in glob.glob("/proc/self/task/*/children") for pid in open(path).read().split()]:
        for pid in pids:
            try:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)
            except (ProcessLookupError, ChildProcessError):
                pass


def run(label, command, show=False, timeout=None, limit=16 << 20, limited=True, env=None, stdin=subprocess.DEVNULL):
    """Runs command and returns its status, stdout, and stderr. With show, its output goes through Visible to stderr."""
    proc = start(command, subprocess.STDOUT if show else subprocess.PIPE, limited, env, stdin)
    pipes = [proc.stdout] if show else [proc.stdout, proc.stderr]
    data = {pipe: bytearray() for pipe in pipes}
    shown = Visible(sys.stderr.buffer)
    deadline = timeout and time.monotonic() + timeout
    total = 0
    try:
        while pipes:
            wait = deadline and deadline - time.monotonic()
            if deadline and wait <= 0:
                die(f"{label} took longer than {timeout} seconds")
            for pipe in select.select(pipes, [], [], wait)[0]:
                block = os.read(pipe.fileno(), 65536)
                if not block:
                    pipes.remove(pipe)
                    continue
                total += len(block)
                if total > limit:
                    die(f"{label} wrote more than {limit} bytes")
                if show:
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
        Visible(sys.stderr.buffer).write(err, final=True)
        die(f"git {args[0]} failed")
    return subprocess.CompletedProcess(args, status, out, err)


def output(*args):
    return git(*args).stdout.decode("utf-8", "t3-pull").strip()


def show_diff(base, commit):
    pager = output("var", "GIT_PAGER") if sys.stdout.isatty() else ""
    diff = start(git_command("diff", *DIFF, base, commit), subprocess.STDOUT)
    proc = None
    quit = False
    try:
        if pager in ("", "cat"):
            out = sys.stdout.buffer
        else:
            # Git sets these for its pager too.
            env = {"LESS": "FRX", "LV": "-c", **os.environ}
            proc = subprocess.Popen(pager, shell=True, stdin=subprocess.PIPE, env=env)
            out = proc.stdin
        shown = Visible(out)
        try:
            while block := diff.stdout.read1(65536):
                shown.write(block)
            shown.write(b"", final=True)
            if proc:
                out.close()
        except BrokenPipeError:
            quit = True
        if not quit:
            diff.wait()
        pager_failed = proc is not None and proc.wait() != 0
    finally:
        if proc:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
            try:
                proc.stdin.close()
            except BrokenPipeError:
                pass
        stop(diff)
    if pager_failed:
        die("the pager failed; nothing changed")
    if diff.returncode and not quit:
        die("showing the diff failed; nothing changed")


def merge(parent, base, commit):
    """Returns the tree that cherry-picking commit onto base gives, without touching the work tree."""
    status, out, err = run("git merge-tree", git_command("merge-tree", "--write-tree", "-z", "--name-only", "--no-messages", f"--merge-base={parent}", base, commit))
    if status not in (0, 1):
        Visible(sys.stderr.buffer).write(err, final=True)
        die("git merge-tree failed")
    tree, *conflicts = out.split(b"\0")
    conflicts = sorted(set(name for name in conflicts if name))
    if status or conflicts:
        die("the commit conflicts with the default branch in these files; ask the agent to rebase it. Nothing changed.\n" + b"\n".join(conflicts).decode("utf-8", "t3-pull"))
    return output("rev-parse", "--verify", f"{tree.decode()}^{{tree}}")


def patch_id(old, new):
    # --verbatim keeps whitespace in the ID. A failed diff only makes the IDs differ.
    diff = start(git_command("diff", *DIFF, old, new), subprocess.DEVNULL)
    try:
        status, out, err = run("git patch-id", git_command("patch-id", "--verbatim"), stdin=diff.stdout)
    finally:
        stop(diff)
    if status:
        Visible(sys.stderr.buffer).write(err, final=True)
        die("git patch-id failed")
    return out.split(b" ")[0]


def risky_files(base, commit):
    names = git("diff", "--name-only", "-z", base, commit, "--", *RISKY).stdout.split(b"\0")
    # Symlinks can redirect any of the risky paths or their parents.
    raw = git("diff", "--raw", "-z", "--no-renames", base, commit).stdout.split(b"\0")
    names += [path for info, path in zip(raw[::2], raw[1::2]) if b"120000" in info[1:].split(b" ")[:2]]
    return sorted(set(name for name in names if name))


def encrypted_files(base, commit):
    # Anyone can encrypt a SOPS file to the public keys in .sops.yaml, and its diff shows only ciphertext.
    changed = set(git("diff", "--name-only", "-z", "--no-renames", base, commit).stdout.split(b"\0"))
    names = set()
    for rev in (base, commit):
        status, out, err = run("git grep", git_command("grep", "-l", "-z", "--text", "-E", SOPS, rev))
        if status not in (0, 1):
            Visible(sys.stderr.buffer).write(err, final=True)
            die("git grep failed")
        prefix = f"{rev}:".encode()
        names |= {name.removeprefix(prefix) for name in out.split(b"\0") if name}
    return sorted(names & changed)


class Parser(argparse.ArgumentParser):
    def error(self, message):
        die(f"{message}\n{self.format_usage().strip()}")


def main():
    if sys.platform != "linux" or ctypes.CDLL(None, use_errno=True).prctl(PR_SET_CHILD_SUBREAPER, 1):
        die("cannot become a subreaper, which t3-pull needs to stop SSH and other descendants of Git")
    parser = Parser(prog="t3-pull", description="Pulls one commit from a branch in the t3 user's clone, shows it, and cherry-picks it as a signed commit.")
    parser.add_argument("--check", action="store_true", help="run the formatting and flake checks afterwards")
    parser.add_argument("--host", help="pull from the t3 user on another host")
    parser.add_argument("branch")
    parser.add_argument("source", nargs="?", metavar="t3 repository path")
    args = parser.parse_args()
    branch, host = args.branch, args.host
    if not NAME.fullmatch(branch) or git("check-ref-format", "--branch", branch, check=False).returncode:
        die(f"not a branch name: {branch}")
    if host is not None and not HOST.fullmatch(host):
        die(f"not a host name: {host}")
    os.chdir(output("rev-parse", "--show-toplevel"))
    source = args.source or f"/var/lib/t3/{os.path.basename(os.getcwd())}"
    if not PATH.fullmatch(source):
        die(f"not a repository path: {source}")
    where = host or "this host"

    current = git("symbolic-ref", "--quiet", "--short", "HEAD", check=False).stdout.decode().strip()
    if not current:
        die("check out a branch first")
    upstream = git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}", check=False).stdout.decode().strip()
    remote = git("config", f"branch.{current}.remote", check=False).stdout.decode().strip()
    if not upstream or not remote:
        die(f"{current} has no upstream branch")
    if git("diff", "--quiet", check=False).returncode or git("diff", "--cached", "--quiet", check=False).returncode:
        die("commit or stash your changes first")
    # followRemoteHEAD updates the remote's HEAD in the same fetch, in case the default branch changed.
    if run("git fetch", git_command("-c", f"remote.{remote}.followRemoteHEAD=always", "fetch", "--quiet", remote), show=True)[0]:
        die(f"cannot fetch {remote}")
    default = git("rev-parse", "--abbrev-ref", f"{remote}/HEAD", check=False).stdout.decode().strip()
    if upstream != default:
        die(f"{current} tracks {upstream}, not the default branch {default or 'of ' + remote}")
    # The update workflow pushes to main every day, so a branch that is only behind is fast-forwarded.
    base = output("rev-parse", upstream)
    if output("rev-parse", "HEAD") != base:
        if git("merge-base", "--is-ancestor", "HEAD", base, check=False).returncode:
            die(f"{current} has commits that {upstream} lacks; push or drop them first")
        if run("git merge", git_command("merge", "--ff-only", "--quiet", base), show=True)[0]:
            die(f"cannot fast-forward {current} to {upstream}")

    ref = f"refs/t3-pull/{branch}"
    with tempfile.NamedTemporaryFile("w", prefix="t3-pull-") as known:
        try:
            # Everything on the t3 side, including upload-pack, runs as t3 and is under the agent's control. On this host,
            # the host key is pinned to the one in /etc/ssh. Another host must already be in Carmilla's known hosts.
            ssh = "ssh -o StrictHostKeyChecking=yes -o ForwardAgent=no -o ForwardX11=no -o ClearAllForwardings=yes -o PermitLocalCommand=no"
            if host is None:
                for name in os.listdir("/etc/ssh"):
                    if re.fullmatch(r"ssh_host_.*_key\.pub", name):
                        with open(f"/etc/ssh/{name}") as key:
                            known.write("127.0.0.1 " + " ".join(key.read().split()[:2]) + "\n")
                known.flush()
                ssh += f" -o UserKnownHostsFile={known.name} -o GlobalKnownHostsFile=/dev/null -o CanonicalizeHostname=no"
            print(f"Fetching {branch} from {source} on {where}. Touch the YubiKey if it flashes.", file=sys.stderr)
            url = f"ssh://t3@{host or '127.0.0.1'}{source}"
            fetch = git_command("fetch", "--quiet", "--no-tags", "--no-write-fetch-head", f"--upload-pack={UPLOAD_PACK}", url, f"+refs/heads/{branch}:{ref}")
            # GIT_SSH_COMMAND overrides core.sshCommand, so an inherited one would replace this command.
            if run("git fetch", fetch, show=True, timeout=600, limit=1 << 20, env={**os.environ, "GIT_SSH_COMMAND": ssh})[0]:
                die(f"cannot fetch {branch} from {source} on {where}")
            commit = output("rev-parse", "--verify", f"{ref}^{{commit}}")
            if int(output("cat-file", "-s", commit)) > 65536:
                die(f"{branch} has a commit message or author over 64 KiB")

            # One commit with one parent from the default branch's history. The tree it gives on the reviewed base is
            # computed first, so what is shown is the tree that lands, even when the default branch moved.
            parents = output("rev-list", "--parents", "-n", "1", commit).split()
            if len(parents) != 2:
                die(f"{branch} must be one commit with one parent; ask the agent to squash it")
            parent = parents[1]
            if git("merge-base", "--is-ancestor", parent, base, check=False).returncode:
                die(f"{branch} must be one commit on a commit of {upstream}; ask the agent to rebase it")
            header = git("log", "-1", "--format=fuller", commit).stdout
            if visible_text(header.decode("utf-8", "t3-pull")).encode() != header:
                die(f"{branch} has control characters, invalid UTF-8, or invisible characters in its message or author")
            tree = merge(parent, base, commit)
            if tree == output("rev-parse", f"{base}^{{tree}}"):
                die(f"{branch} changes nothing on {upstream}")

            moved = int(output("rev-list", "--count", f"{parent}..{base}"))
            # A merge can put a change in another place than the agent did, for example into a file that was renamed.
            differs = moved and patch_id(parent, commit) != patch_id(base, tree)
            if differs:
                print(f"{upstream} moved since the agent's commit, and the change that lands differs from the agent's diff. This is the agent's diff:", file=sys.stderr)
                show_diff(parent, commit)
                print("This is the change that lands:", file=sys.stderr)
            show_diff(base, tree)
            shown = Visible(sys.stdout.buffer)
            shown.write(header + b"\n")
            shown.write(git("diff", "--stat", *DIFF, base, tree).stdout)
            risky = risky_files(base, tree)
            if risky:
                shown.write(b"\nThis commit changes files that act later:\n" + b"\n".join(risky) + b"\n")
            encrypted = encrypted_files(base, tree)
            if encrypted:
                shown.write(b"\nThis commit changes encrypted files, whose diff shows only ciphertext:\n" + b"\n".join(encrypted) + b"\n")
            shown.write(b"", final=True)
            if moved:
                same = "differs from the agent's diff; compare both diffs above" if differs else "is the same as the agent's diff"
                print(f"\n{upstream} moved {moved} commit{'s' * (moved != 1)} past the agent's commit, which applies without conflicts. The change that lands {same}.", file=sys.stderr)
            print(f"Pull {commit} from {branch} onto {current} and sign it? [y/N] ", end="", file=sys.stderr, flush=True)
            if sys.stdin.readline().strip() != "y":
                die("nothing changed")

            # The review holds only for the base it was computed on.
            if output("rev-parse", "HEAD") != base or git("diff", "--quiet", check=False).returncode or git("diff", "--cached", "--quiet", check=False).returncode:
                die(f"{current} changed during the review; nothing changed")
            if run("git cherry-pick", git_command("cherry-pick", "-S", commit), show=True)[0]:
                die("the cherry-pick failed; run git cherry-pick --abort")
            if output("rev-parse", "HEAD^") != base or output("rev-parse", "HEAD^{tree}") != tree:
                die(f"HEAD does not hold the reviewed tree; undo it with git reset --keep {base}")
        finally:
            git("update-ref", "-d", ref, check=False)

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
