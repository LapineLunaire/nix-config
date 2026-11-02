# T3 Code

Camellya and Kafka run the T3 Code server as the `t3` user on port 3773, with its home in `/var/lib/t3`. Lingering starts it at boot. The firewall restricts it to the same trusted subnets as SSH; Kafka also requires a trusted NetworkManager connection. `t3` is a system account, so the login screen does not list it.

The `t3` user has its own Claude Code, Codex, Git, and Forgejo logins. It is not in `wheel`, cannot read Carmilla's home or `/persist/nix-config`, and cannot sign commits. Agents can still read files that are world-readable, use the network, and build with Nix.

Carmilla's desktop app is a client of the server. A rebuild keeps the app's local environment off, because that would run agents as Carmilla. The app's native folder picker is off in this mode.

## Setup

Quit the app and switch from a normal terminal. Package updates restart the service and interrupt its agents, and an open app can undo its settings when it closes. Threads from the earlier server under Carmilla's `~/.t3` stay there; the `t3` server starts empty.

The `t3` Forgejo account is restricted, so it only sees what it is given: it belongs to the `ReadOnly` team of the `lune` organization, which can read all of the organization's repositories and write to none. Keep it out of the trusted users for Actions, and do not approve its workflow runs (see [pull requests](#pull-requests)). ci-runner is registered for `lune` only, under the organization's **Settings → Actions → Runners**, so workflows in `t3`'s own forks find no runner.

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

Agents follow [their instructions](../users/t3/agents.md): they fork the repository to the `t3` account, push their branch to the fork, and open a pull request against the original. They run checks themselves as `t3`.

Forgejo runs the workflow files from a pull request, including its changes, once the run is approved. A read-only fork's runs wait for approval, and the validation workflow also skips pull requests from forks. Approving a `t3` run would execute the agent's workflows on the shared runner, so leave them unapproved.

Review the pull request in Forgejo or in a checkout of your own. Do not open the `t3` user's directories or enter a development shell from the pull request as Carmilla, because that runs the agent's code as her.

Land it from a clean checkout of the default branch, on a host with the YubiKey:

```sh
t3-land <pull request number>
```

`t3-land` fetches the pull request's head commit, shows its commits, and asks before merging. It names changed files that run code later: the repository's Git hooks, `.forgejo`, and `.envrc`. It then creates one signed merge commit with `--no-ff` and pushes it, with Git hooks disabled throughout. That signature covers the agent's unsigned commits, so Sparkle and Sparxie accept them.

It refuses to run if the branch is behind its remote or has uncommitted changes. It also refuses if Git filters or merge drivers are configured, or if the repository's own config includes other files or sets SSH, signing, or credential programs, because those could run the pull request's files. Git hooks, fsmonitor, and the pager are off throughout. If the merge conflicts or signing fails, it aborts the merge and changes nothing. A pull request updated after review gets a new head commit, so check the commits it prints.

Turn on **Autodetect manual merge** under each repository's pull request settings, so Forgejo marks the pull request as merged when the merge reaches the default branch. Without it, use **Manually merged** on the pull request. Branches stay in the `t3` account's forks after a merge; delete them there.

Repositories that nothing deploys from can use Forgejo's merge button. In `nix-config`, Forgejo's merge commits are not signed by an `allowedSigners` key, so the servers would refuse them.
