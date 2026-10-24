# Automated updates

| UTC | Event |
|---|---|
| 02:00 | CI runner store reset |
| 03:00 | Sparkle and Sparxie backups |
| 04:00 | Server upgrades, with up to 15 minutes of jitter |
| 05:00 | Forgejo update and build workflow |
| 12:00 | Borg freshness check |

The [update workflow](../.forgejo/workflows/flake-update.yml) also supports manual runs. Updates queue per branch, and each run checks out the latest branch to include earlier update commits.

On Mondays and manual runs the job refreshes Home Assistant's container digest. It then updates the flake inputs in two groups:

- The server-only inputs in `SERVER_INPUTS` update first, with the Caddy plugin hash refreshed if necessary. They must pass the flake check and a Sparkle build.
- The remaining inputs update next. They must pass the flake check and builds of Sparkle, Camellya, and Kafka.

A group that fails is rolled back, and the other group's update still goes ahead. If anything changed, the job checks all systems again, builds Camellya, Kafka, and Sparkle, including Sparkle's guest runners, and pushes one signed commit with the combined changes. If a group was rolled back, the run then fails and names that group. Sparxie and Silverwolf are evaluated but not built by the x86_64 Linux runner.

`CI_SIGNING_KEY` supplies the SSH signing key. With `ATTIC_TOKEN` set, the workflow uploads Sparkle to the `server` cache and Camellya and Kafka to the `desktop` cache before committing and pushing. An upload failure blocks the push; without a token, uploads are skipped. Temporary signing keys and cache credentials are removed when their steps finish.

## Server upgrades

Sparkle and Sparxie verify the signature on `origin/main` against `host.autoUpdate.allowedSigners`, then reset `/persist/nix-config` to that commit. This discards uncommitted tracked changes and unpushed commits on the checked-out branch. Commit and push from Camellya, Kafka, or Silverwolf with its configured signing identity.

Sparxie reboots when the kernel, kernel modules, or initrd change. Sparkle restarts changed running guests; boot changes need a manual reboot and the pool passphrase. Failed upgrades mail the last 50 log lines. Upgrades and backups never overlap: an upgrade waits for a running backup, and a backup waits for a running upgrade and the reboot it may schedule. Commits pushed after the upgrade check wait for the next night. Desktop activation remains manual.

The 05:00 workflow prepares updates for the following day's upgrade.

The CI store reset and server upgrades do not wait for running jobs, so long or manual workflows can be interrupted. See [guest operations](guests.md#ci-store) for store reset recovery.
