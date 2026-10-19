# Automated updates

| UTC | Event |
|---|---|
| 02:00 | CI runner store reset |
| 03:00 | Sparkle and Sparxie backups |
| 04:00 | Server upgrades, with up to 15 minutes of jitter |
| 05:00 | Forgejo update and build workflow |
| 12:00 | Borg freshness check |

The [update workflow](../.forgejo/workflows/flake-update.yml) also supports manual runs. Updates queue per branch, and each run checks out the latest branch to include earlier update commits.

The job updates `flake.lock` and refreshes the Caddy plugin hash if necessary. On Mondays and manual runs it also refreshes Home Assistant's container digest. If either changes, it evaluates all systems and builds Camellya, Kafka, and Sparkle, including Sparkle's guest runners, once before pushing a signed commit with the combined changes. Sparxie and Silverwolf are evaluated but not built by the x86_64 Linux runner.

`CI_SIGNING_KEY` supplies the SSH signing key. With `ATTIC_TOKEN` set, the workflow uploads Sparkle to the `server` cache and Camellya and Kafka to the `desktop` cache before committing and pushing. An upload failure blocks the push; without a token, uploads are skipped. Temporary signing keys and cache credentials are removed when their steps finish.

## Server upgrades

Sparkle and Sparxie verify the signature on `origin/main` against `host.autoUpdate.allowedSigners`, then reset `/persist/nix-config` to that commit. This discards uncommitted tracked changes and unpushed commits on the checked-out branch. Commit and push from Camellya, Kafka, or Silverwolf with its configured signing identity.

Sparxie reboots when the kernel, kernel modules, or initrd change. Sparkle restarts changed running guests; boot changes need a manual reboot and the pool passphrase. Failed upgrades mail the last 50 log lines. Commits pushed after the upgrade check wait for the next night. Desktop activation remains manual.

The 05:00 workflow prepares updates for the following day's upgrade.

The CI store reset and server upgrades do not wait for running jobs, so long or manual workflows can be interrupted. See [guest operations](guests.md#ci-store) for store reset recovery.
