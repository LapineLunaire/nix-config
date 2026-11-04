# T3 Code

Camellya and Kafka run the T3 Code server as the `t3` user on port 3773, with its home in `/var/lib/t3`. Lingering starts it at boot. The firewall restricts it to the same trusted subnets as SSH; Kafka also requires a trusted NetworkManager connection. `t3` is a system account, so the login screen does not list it.

The `t3` user has its own Claude Code, Codex, Git, and Forgejo logins. It is not in `wheel`, cannot read Carmilla's home or `/persist/nix-config`, and cannot sign commits. Agents can still read files that are world-readable, use the network, and build with Nix.

Carmilla's desktop app is a client of the server. A rebuild keeps the app's local environment off, because that would run agents as Carmilla. The app's native folder picker is off in this mode.

## Setup

Quit the app and switch from a normal terminal. Package updates restart the service and interrupt its agents, and an open app can undo its settings when it closes.

The `t3` Forgejo account is restricted, so it only sees what it is given: it belongs to the `ReadOnly` team of the `lune` organization, which can read all of the organization's repositories and write to none. Keep it out of the trusted users for Actions, so workflow runs require review and approval (see [pull requests](#pull-requests)). ci-runner is registered for `lune` only, under the organization's **Settings → Actions → Runners**, so workflows in `t3`'s own forks find no runner.

Open a shell as `t3`:

```sh
doas machinectl shell t3@
```

In that shell:

1. Log in with `claude` and `codex login`.
2. Create an SSH key with `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`, and add `~/.ssh/id_ed25519.pub` to the `t3` Forgejo account.
3. Create an access token in the `t3` account's settings with repository and issue write access, then run `fj -H git.lunaire.moe auth add-token` and paste it.
4. Clone the repositories agents work on over SSH, for example `git clone forgejo@git-ssh.lunaire.moe:lune/nix-config.git`.
5. Run `t3 pair` and note the token.

Pair the app as Carmilla once on each host. Use the loopback address, because the LAN address in the printed link changes between networks:

```sh
t3code-desktop "t3code://pair?pairingUrl=http%3A%2F%2F127.0.0.1%3A3773%2Fpair%23token%3D<token>"
```

Then add the cloned repositories as projects in the app. Check the service with `doas systemctl --user -M t3@ status t3code` and its logs with `doas journalctl _SYSTEMD_USER_UNIT=t3code.service`.

## Pull requests

Agents follow [their instructions](../users/t3/agents.md): they fork the repository to the `t3` account, keep the fork's default branch up to date with the original, push their branch to the fork, and open a pull request against the original. They use targeted local checks while developing and leave the full repository checks to CI.

Forgejo runs a pull request's own workflow files once the run is approved. Before approving a run on the shared runner, review the changes, including workflows, local actions, and code they execute. An approved run can read the runner's read-only cache token, `ATTIC_PULL_TOKEN`, and send it elsewhere; see [secrets](secrets.md). If the branch changes, review the new changes before approving their run.

Review the pull request in Forgejo or in a checkout of your own. Do not open the `t3` user's directories or enter a development shell from the pull request as Carmilla, because that runs the agent's code as her.

Land it from a clean checkout of the default branch, on a host with the YubiKey:

```sh
t3-land [--prepare] <pull request number> [remote]
```

`t3-land` fetches the pull request's head commit and reads the pull request from the Forgejo API at `git.lunaire.moe` without a token, so it works only for public repositories. It shows the commits and the files the squashed commit changes, and names changed files that act later: Git hooks, `.forgejo`, `.envrc`, `flake.nix`, `flake.lock`, `.sops.yaml`, the project settings in `.claude`, `.codex`, `.mcp.json`, and `.zed`, agent instructions in `AGENTS.md` and `CLAUDE.md`, and any symlink. After you confirm, it squashes the pull request into one commit on top of the default branch, with the pull request's title as the subject and you as author and committer, and you sign it. So the default branch stays linear, every commit on it is signed, and each pull request needs one signature.

It pushes the commit to the pull request's branch on the agent's fork first, then to the default branch, so Forgejo finds the pull request's head on the default branch and marks it as merged. This needs **Autodetect manual merge** on in the repository's pull request settings, and write access to the agent's fork, which your owner-level access on `git.lunaire.moe` gives you. If the agent pushed after the head that `t3-land` fetched, the push to the fork fails, so later commits are never dropped; review them and run it again. If the default branch moved before the second push, the fork holds the squashed commit; pull and run `t3-land` again to make the commit on top of the new tip and stop for CI.

`t3-land <number>` lands only if CI passed on the pull request's head and the pull request contains the latest default branch, so CI checked exactly the files that land. Otherwise, run `t3-land --prepare <number>`: it pushes the squashed commit to the fork for CI and stops. Pushing as you can start the run without approval, so review workflow changes before you confirm. Once that run passes, `t3-land <number>` pushes the same commit to the default branch. If the pull request or the default branch moved in between, it makes the commit again and stops for CI again.

It refuses to run if the branch does not match its remote or has uncommitted changes, if CI has not passed as described above, or if the pull request is closed, targets another branch, conflicts, has no one-line title, or has commit messages or authors that are not valid UTF-8. If Forgejo has not updated the pull request to the squashed commit within 30 seconds, it stops before pushing to the default branch; run it again once CI passes on that commit. Its Git commands inherit no `GIT_*` environment variables and skip the system and global Git config, keeping only `user.name`, `user.email`, `user.signingkey`, and `gpg.format` from them, so helpers configured there cannot run the pull request's files. It refuses if the repository's own or worktree config sets filters, merge or diff drivers, hooks, includes, protocol settings, or SSH, askpass, proxy, signing, or credential programs. Git hooks, fsmonitor, and the pager are off. It pushes to the fork only at the Forgejo SSH address the API names. It makes, signs, and pushes the commit before updating the checkout, so SSH and signing run while the work tree still holds the default branch's files. The agent can push after your review, so check that the commits it prints are the ones you reviewed.

After landing, the agent's branch on the fork holds the squashed commit. Delete it in the `t3` account's fork.

Repositories that nothing deploys from can use Forgejo's merge button. In `nix-config`, Forgejo's merge commits are not signed by an `allowedSigners` key, so the servers would refuse them.
