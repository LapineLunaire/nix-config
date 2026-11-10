# T3 Code

Camellya and Kafka run the T3 Code server as the `t3` user on port 3773, with its home in `/var/lib/t3`. Lingering starts it at boot. The firewall restricts it to the same trusted subnets as SSH; Kafka also requires a trusted NetworkManager connection. `t3` is a system account, so the login screen does not list it.

The `t3` user has its own Claude Code, Codex, Git, and Forgejo logins. It is not in `wheel`, cannot read Carmilla's home or `/persist/nix-config`, and cannot sign commits. Agents can still read files that are world-readable, use the network, and build with Nix.

Carmilla's desktop app is a client of the server. A rebuild keeps the app's local environment off, because that would run agents as Carmilla. The app's native folder picker is off in this mode.

## Setup

Quit the app and switch from a normal terminal. Package updates restart the service and interrupt its agents, and an open app can undo its settings when it closes.

The `t3` Forgejo account is restricted, so it only sees what it is given: it belongs to the `ReadOnly` team of the `lune` organization, which can read all of the organization's repositories and write to none. Agents only fetch from Forgejo; Carmilla pulls their work [on the host](#pulling-agent-work).

Open a shell as `t3`:

```sh
doas machinectl shell t3@
```

In that shell:

1. Log in with `claude` and `codex login`.
2. Create an SSH key with `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`, and add `~/.ssh/id_ed25519.pub` to the `t3` Forgejo account.
3. Clone the repositories agents work on over SSH into the home directory, for example `git clone forgejo@git-ssh.lunaire.moe:lune/nix-config.git`. `t3-pull` looks for `/var/lib/t3/<name of your checkout>` by default.
4. Run `t3 pair` and note the token.

Pair the app as Carmilla once on each host. Use the loopback address, because the LAN address in the printed link changes between networks:

```sh
t3code-desktop "t3code://pair?pairingUrl=http%3A%2F%2F127.0.0.1%3A3773%2Fpair%23token%3D<token>"
```

Then add the cloned repositories as projects in the app. Check the service with `doas systemctl --user -M t3@ status t3code` and its logs with `doas journalctl _SYSTEMD_USER_UNIT=t3code.service`.

## Pulling agent work

Agents follow [their instructions](../users/t3/agents.md): each change is one commit on a local branch in `t3`'s clone, started from the default branch. They run the checks that cover the change and report the host, the clone's path, the branch, the commit SHA, and the results. Follow-up work on a pull request starts from that pull request's branch instead; see [pull request branches](#pull-request-branches).

Pull it from a clean checkout of the default branch on Camellya or Kafka, where `t3-pull` is installed. The YubiKey signs and pushes, so work from the host it is plugged into; `--host` pulls from the other desktop, for example `--host camellya` on Kafka. The repository path defaults to `/var/lib/t3/<name of your checkout>`; pass the path the agent reported if it differs, with or without its `/.git`:

```sh
t3-pull [--check] [--host <host>] [--onto <your branch>] <branch> [t3 repository path]
```

`t3-pull` fetches your branch's remote, updating which branch it records as the remote's default, requires your branch to track the remote's default branch, and fast-forwards it if it is behind. It then fetches the agent's branch over SSH as `t3`. The connection forwards nothing and does not reuse a shared SSH connection. Everything on the `t3` side runs as `t3` and is under the agent's control, so `t3-pull` treats what it receives as hostile. On this host it connects to `127.0.0.1` and trusts only the host key in `/etc/ssh`. Another host must already be in your known hosts, because `t3-pull` does not ask about new host keys; run `ssh t3@<host> true` once and check the key. Each fetch can ask for a YubiKey touch. The fetch from `t3` refuses malformed Git objects, such as trees that hold a path twice, and does not fetch submodules. It stops after 10 minutes or 1 MiB of messages, and keeps what it receives as one pack. Every Git command that reads what came from `t3`, up to the signing, has memory, CPU-time, and file-size limits.

It takes one commit with one parent, and the parent must be on the remote's default branch. Before asking you, it works out with `git merge-tree` what applying the commit to the default branch gives, without touching the work tree. It refuses a commit that conflicts or changes nothing there, or that would overwrite or delete files Git does not track, including ignored ones such as a local `.env`. Everything it shows compares the default branch with that result, so what you review is the tree that lands. If the default branch moved past the agent's commit, it says by how many commits.

It does not run while your Git config sets any of these:

- a merge driver, which would run on the agent's files while merging
- a hook (`hook.<name>.command`), which ignores `core.hooksPath` and would run while fetching and landing the commit
- `fetch.fsck`, which would let malformed objects through
- `fetch.uriProtocols`, which would let the `t3` side send Git to download from other URLs
- `promisor.acceptFromServer` or `promisor.acceptFromServerUrl`, which would let the `t3` side send Git to other URLs and add remotes to your config

It shows the diff in `less`, not your pager, because a pager can act on the text: nvimpager, for one, follows Vim modelines unless Git started it. `less` runs with `LESSSECURE` and none of your `LESS` variables. The diff is text, with every submodule, without external diff or textconv programs, `.gitattributes` marking files as binary, or your diff settings hiding anything. A renamed or copied file shows in full, as a new file. The commit's SHA, message, and diff stat follow it. In everything it shows, including the output of Git and the fetch, control characters, invalid UTF-8, invisible characters such as bidi controls and zero-width characters, and spaces other than the plain space are shown as `\x{..}` escapes, so they cannot send commands to your terminal or hide in the text. A carriage return right before a newline, which SSH ends its messages with, is dropped from the output of Git and the fetch; the diff keeps it. An escape looks the same as its characters typed out, so if the diff has any, `t3-pull` says so after it. A commit with any of them in its message or headers, with an encoding header, with a message that is empty or starts with a blank line, or over 64 KiB, is refused, because the message lands on the default branch as it is. So is a diff over 16 MiB, which is too much to review.

It also names changed files that act later. The list is a reminder, not a complete check: read the whole diff, and check that the SHA is the one the agent reported.

- Git hooks in `.githooks` or wherever `core.hooksPath` points, and the hooks and settings of husky, pre-commit, and lefthook
- files your Git config includes
- workflows in `.forgejo`, `.gitea`, and `.github`
- `flake.nix` and `flake.lock`
- project settings in `.codex`, `.mcp.json`, `.vscode`, and `.zed`
- `.lfsconfig` and `.gitmodules`
- in any directory: `.envrc`, `.sops.yaml`, `.gitattributes`, project settings in `.claude`, skills and plugins in `.agents`, and agent instructions in `AGENTS.md`, `AGENTS.override.md`, `CLAUDE.md`, and `CLAUDE.local.md`
- any symlink and any submodule

A change under `.forgejo` runs on the runner as soon as you push, with the repository's secrets, including `CI_SIGNING_KEY`, which the servers trust.

It names changed files that look encrypted with SOPS separately. Anyone can encrypt values to the public keys in `.sops.yaml`, and the diff shows only ciphertext, so the agent could replace a secret with one it chose. After the commit lands, check the values with `sops decrypt <file>` before you push. `t3-pull` looks for the `sops` metadata key and SOPS ciphertext, which escapes in YAML or JSON can hide, so treat any ciphertext in the diff the same way.

After you confirm, it checks that your branch has not changed and that no untracked files are in the way, then makes a signed commit of the tree and message you reviewed on top of your branch, checks both again, and fast-forwards your branch to it with Git hooks off. Your Git identity is its author and committer, so platforms that attribute code count it as yours; the agent's name and dates do not land. If signing fails, nothing has changed. `--check` then runs the formatting check and the flake check of all systems. Push it yourself with `git push`. The servers deploy it only because you signed it; see [server upgrades](updates.md#server-upgrades).

From the fast-forward on, the work tree holds the agent's files, and they run as you. The agent's `.gitattributes` picks which files the fast-forward runs your Git filters on, such as Git LFS, and can make Git rewrite the files it checks out, for example with `working-tree-encoding`, so that they differ from the diff you reviewed. Then direnv loads the development shell at your next prompt, `--check` runs the flake's formatter, your next `git commit` or `git push` runs hooks in `.githooks`, and files your Git config includes take effect, with any hooks they set. Review before you confirm, and do not open the `t3` user's directories or enter a development shell from them.

If the commit conflicts with the default branch, ask the agent to rebase. Once you have pushed, the agent deletes its branch. When `t3-pull` refuses, its message says what to do next.

### Pull request branches

For a follow-up commit on a pull request, such as a fix for a review, the agent starts from the pull request's branch and reports the command to run. Check that branch out, with nothing unpushed on it, and name it with `--onto`:

```sh
git switch <your branch>
t3-pull --onto <your branch> <branch> [t3 repository path]
```

The branch needs an upstream branch, which can be in a fork and under another name. Everything above then holds with that upstream branch in place of the default branch: `t3-pull` fetches its remote, fast-forwards your branch if it is behind, requires the commit's parent to be in the upstream branch's history, and shows, signs, and lands what the commit gives on its head. The fetch from `t3`, the checks on the message, and the signing are the same.

`t3-pull` does not work out the target from the branch you are on. Without `--onto` it only lands on a branch that tracks the default branch, and with it only on the named branch while that is checked out. A commit therefore cannot land on a pull request's branch because you happened to be on it, or on another branch than the one you named.

The agent's clone is readable only by `t3`, so `git fetch <host>:/var/lib/t3/<name>` under your own login fails. `t3-pull` logs in as `t3`.
