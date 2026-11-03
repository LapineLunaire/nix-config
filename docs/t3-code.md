# T3 Code

Camellya and Kafka run the T3 Code server as the `t3` user on port 3773, with its home in `/var/lib/t3`. Lingering starts it at boot. The firewall restricts it to the same trusted subnets as SSH; Kafka also requires a trusted NetworkManager connection. `t3` is a system account, so the login screen does not list it.

The `t3` user has its own Claude Code, Codex, Git, and Forgejo logins. It is not in `wheel`, cannot read Carmilla's home or `/persist/nix-config`, and cannot sign commits. Agents can still read files that are world-readable, use the network, and build with Nix.

Carmilla's desktop app is a client of the server. A rebuild keeps the app's local environment off, because that would run agents as Carmilla. The app's native folder picker is off in this mode.

## Setup

Quit the app and switch from a normal terminal. Package updates restart the service and interrupt its agents, and an open app can undo its settings when it closes. Threads from the earlier server under Carmilla's `~/.t3` stay there; the `t3` server starts empty.

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

Forgejo runs the workflow files from a pull request, including its changes, once the run is approved. Review the changes, including workflows, local actions, and code they execute, before approving a run on the shared runner. An approved run can read the runner's read-only cache token, `ATTIC_PULL_TOKEN`, and send it elsewhere; see [secrets](secrets.md). Wait for validation to pass on the latest pull request head before merging. If the branch changes, review the new changes and wait for their checks. `t3-land` does not enforce CI status.

Review the pull request in Forgejo or in a checkout of your own. Do not open the `t3` user's directories or enter a development shell from the pull request as Carmilla, because that runs the agent's code as her.

Land it from a clean checkout of the default branch, on a host with the YubiKey:

```sh
t3-land [--prepare] <pull request number>
```

`t3-land` fetches the pull request's head commit and reads the pull request from the Forgejo API at `git.lunaire.moe`. It shows the commits and the changed files, and names changed files that run code later: the repository's Git hooks, `.forgejo`, `.envrc`, `flake.nix`, `flake.lock`, and any symlink. After you confirm, it squashes the pull request into one commit on top of the default branch, with the pull request's title as the subject and you as author and committer, and you sign it. So the default branch stays linear, every commit on it is signed, and each pull request needs one signature.

It pushes the commit to the pull request's branch on the agent's fork first, then to the default branch, so Forgejo finds the pull request's head on the default branch and marks it as merged. This needs **Autodetect manual merge** on in the repository's pull request settings, and write access to the agent's fork, which your owner-level access on `git.lunaire.moe` already gives you. The push to the fork fails if the agent pushed after the head that `t3-land` fetched, so later commits are never dropped; review them and run it again. If the default branch moved before the second push, the fork holds the squashed commit; pull and run `t3-land` again to make it on top of the new tip.

To land only after CI passes on the exact squashed commit, run `t3-land --prepare <number>`. It stops after the push to the fork. Approve the run on the pull request, and once it passes, run `t3-land <number>` to push the same commit to the default branch. If the pull request or the default branch moved in between, it makes the commit again.

It refuses to run if the branch does not match its remote or has uncommitted changes, or if the pull request is closed, targets another branch, conflicts, or has no one-line title. If Forgejo has not updated the pull request to the squashed commit within 30 seconds, it stops before pushing to the default branch; run it again to finish. Its Git commands inherit no `GIT_*` environment variables and skip the system and global Git config, keeping only `user.name`, `user.email`, `user.signingkey`, and `gpg.format` from them, so helpers configured there cannot run the pull request's files. It refuses if the repository's own or worktree config sets filters, merge or diff drivers, hooks, includes other files, or sets SSH, askpass, proxy, protocol, signing, or credential programs. Git hooks, fsmonitor, and the pager are off throughout. It pushes only to the Forgejo SSH address the API names for the fork. It makes, signs, and pushes the commit before updating the checkout, so SSH and signing run while the work tree still holds the default branch's files. A pull request updated after review gets a new head commit, so check the commits it prints.

After landing, the agent's branch on the fork holds the squashed commit. Branches stay in the `t3` account's forks; delete them there.

Repositories that nothing deploys from can use Forgejo's merge button. In `nix-config`, Forgejo's merge commits are not signed by an `allowedSigners` key, so the servers would refuse them.
