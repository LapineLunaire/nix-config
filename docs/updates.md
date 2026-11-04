# Automated updates

| UTC | Event |
|---|---|
| 03:00 | Sparkle and Sparxie backups |
| 04:00 | Server upgrades, with up to 15 minutes of jitter |
| 05:00 | Forgejo update and build workflow |
| 12:00 | Borg freshness check; Sparkle and Sparxie email daily while a reboot is pending |

The [update workflow](../.forgejo/workflows/flake-update.yml) also supports manual runs. Updates queue per branch, and each run checks out the latest branch to include earlier update commits.

On Mondays and manual runs the job refreshes Home Assistant's container digest. It then updates the flake inputs in two groups:

- The server-only inputs in `SERVER_INPUTS` update first, with the Caddy plugin hash refreshed if necessary. They must pass the flake check and a Sparkle build.
- The remaining inputs update next. They must pass the flake check and builds of Sparkle, Camellya, and Kafka.

A group that fails is rolled back, and the other group's update still goes ahead. If anything changed, the job checks all systems again, builds Camellya, Kafka, and Sparkle, including Sparkle's guest runners, and pushes one signed commit with the combined changes. If a group was rolled back, the run then fails and names that group. Sparxie and Silverwolf are evaluated but not built by the x86_64 Linux runner.

`CI_SIGNING_KEY` supplies the SSH signing key. The workflow uploads Sparkle to the `server` cache and Camellya and Kafka to the `desktop` cache with `ATTIC_TOKEN` before committing and pushing. A missing token or failed upload blocks the push. Temporary signing keys and cache credentials are removed when their steps finish.

The [validation workflow](../.forgejo/workflows/validate.yml) checks pull requests and manual runs, not pushes to `main`. A host that pulls a commit the caches lack builds the missing parts itself; the next update run that changes something caches the systems again. Validation builds only uncached systems and uploads nothing. A new push to a pull request cancels its older runs, including runs still waiting for approval. `t3-land` pushes the landed commit to the pull request branch before `main`, which starts a run. If that run is still waiting when Forgejo marks the pull request merged, Forgejo cancels it and the landed commit shows a failed status. A pull request run that finds its commit already in `main` skips its checks. Runs for pull requests from `t3`'s forks need [review and approval](t3-code.md#pull-requests).

## Server upgrades

Sparkle and Sparxie check `origin/main` as described below, then reset `/persist/nix-config` to it. This discards uncommitted tracked changes and unpushed commits on the checked-out branch. Commit and push from Camellya, Kafka, or Silverwolf with its configured signing identity.

- `origin/main` must contain the last deployed commit, stored in `/var/lib/nixos-upgrade/deployed-rev` after each successful rebuild. A force push or rollback is refused. The first upgrade on a new host has no stored commit and skips this check.
- From the tip, commits signed with a `host.autoUpdate.ciSigners` key are walked back to a commit signed with a `host.autoUpdate.allowedSigners` key or the deployed commit. A signature from `allowedSigners` covers the commit's whole history.
- A CI commit must have one parent and change only flake input versions or text matching the patterns in `host.autoUpdate.ciPins`. Flake inputs keep their sources and dependency wiring and cannot move back in time. File modes cannot change. Add new inputs with their lock entries in a signed commit. When the workflow starts refreshing another pinned value, add its file and pattern to `ciPins`.

After a deliberate force push, run `doas rm /var/lib/nixos-upgrade/deployed-rev` on each affected host to accept the rewritten history. The next upgrade still checks commit signatures and CI changes.

A dependency update that adds, removes, renames, or rewires lock entries makes the next CI commit fail this check. Review that commit and push a signed commit on top, such as `git commit --allow-empty -S -m "Accept the flake update"`.

Sparxie reboots when the kernel, kernel modules, or initrd change. Sparkle restarts changed running guests; boot changes need a manual reboot and the pool passphrase. Failed upgrades mail the last 50 log lines. Upgrades and backups never overlap: an upgrade waits for a running backup, and a backup waits for a running upgrade and the reboot it may schedule. Commits pushed after the upgrade check wait for the next night. Desktop activation remains manual.

The 05:00 workflow prepares updates for the following day's upgrade.

Server upgrades do not wait for running jobs, so long or manual workflows can be interrupted. See [guest operations](guests.md#ci-jobs) for the container image and job storage.
