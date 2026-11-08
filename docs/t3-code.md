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

Agents follow [their instructions](../users/t3/agents.md): each change is one commit on a local branch in `t3`'s clone, started from the default branch. They run the checks that cover the change and report the host, the clone's path, the branch, the commit SHA, and the results.

Pull it from a clean checkout of the default branch on Camellya or Kafka, where `t3-pull` is installed. The YubiKey signs and pushes, so work from the host it is plugged into; `--host` pulls from the other desktop, for example `--host camellya` on Kafka. The repository path defaults to `/var/lib/t3/<name of your checkout>`; pass the path the agent reported if it differs:

```sh
t3-pull [--check] [--host <host>] <branch> [t3 repository path]
```

`t3-pull` fetches your branch's remote, requires your branch to track the remote's default branch, and fast-forwards it if it is behind. It then fetches the agent's branch over SSH as `t3`. The connection forwards nothing. Everything on the `t3` side runs as `t3` and is under the agent's control, so `t3-pull` treats what it receives as hostile. On this host it connects to `127.0.0.1` and trusts only the host key in `/etc/ssh`. Another host must already be in your known hosts, because `t3-pull` does not ask about new host keys; run `ssh t3@<host> true` once and check the key. Each fetch can ask for a YubiKey touch. The fetch from `t3` stops after 10 minutes or 1 MiB of messages, and every Git command it runs has memory, CPU-time, and file-size limits.

It takes one commit with one parent, and the parent must be on the remote's default branch. Before asking you, it works out with `git merge-tree` what cherry-picking the commit onto the default branch gives, without touching the work tree. It refuses a commit that conflicts or changes nothing there, and does not run while a merge driver is configured, because the driver would run on the agent's files before you review them. Everything it shows compares the default branch with that result, so what you review is the tree that lands. If the default branch moved past the agent's commit, it says by how many commits. It shows the diff in your pager as text, with every submodule, without external diff or textconv programs, `.gitattributes` marking files as binary, or your diff settings hiding anything, then the author, message, and diff stat. In everything it shows, including the output of Git and the fetch, control characters, invalid UTF-8, and invisible characters such as bidi controls and zero-width characters are shown as `\x{..}` escapes, so they cannot send commands to your terminal or hide in the text. A commit with any of them in its message or author, with an encoding header, or over 64 KiB, is refused, because it would land on the default branch. So is a diff over 16 MiB, which is too much to review.

It also names changed files that act later: Git hooks, `.forgejo`, `.envrc`, `flake.nix`, `flake.lock`, `.sops.yaml`, the project settings in `.claude`, `.codex`, `.mcp.json`, and `.zed`, agent instructions in `AGENTS.md` and `CLAUDE.md`, `.gitattributes`, `.gitmodules`, any symlink, and any submodule. The list is a reminder, not a complete check: read the whole diff, and check that the SHA is the one the agent reported. A change under `.forgejo` runs on the runner as soon as you push, with the repository's secrets, including `CI_SIGNING_KEY`, which the servers trust.

It names changed files that look encrypted with SOPS separately. Anyone can encrypt values to the public keys in `.sops.yaml`, and the diff shows only ciphertext, so the agent could replace a secret with one it chose. After the cherry-pick, check the values with `sops decrypt <file>` before you push. `t3-pull` looks for the `sops` metadata key and SOPS ciphertext, which escapes in YAML or JSON can hide, so treat any ciphertext in the diff the same way.

After you confirm, it checks that your branch has not changed, then cherry-picks the commit with Git hooks off and signs it, and checks that the result has the tree, author, and message you reviewed. The agent stays the author and you become the committer. `--check` then runs the formatting check and the flake check of all systems. Push it yourself with `git push`. The servers deploy it only because you signed it; see [server upgrades](updates.md#server-upgrades).

From the cherry-pick on, the work tree holds the agent's files, and they run as you: direnv loads the development shell at your next prompt, `--check` runs the flake's formatter, and `git push` runs hooks in `.githooks`. Review before you confirm, and do not open the `t3` user's directories or enter a development shell from them.

If the commit conflicts with the default branch, ask the agent to rebase. Once you have pushed, the agent deletes its branch.
