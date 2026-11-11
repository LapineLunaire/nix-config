# Automated updates

| UTC | Event |
|---|---|
| 03:00 | Sparkle and Sparxie backups |
| 04:00 | Server upgrades, with up to 15 minutes of jitter |
| 05:00 | Forgejo update and build workflow |
| 12:00 | Borg freshness check; Sparkle and Sparxie email daily while a reboot is pending |

The [update workflow](../.forgejo/workflows/flake-update.yml) also supports manual runs. Updates queue per branch, and each run checks out the latest branch to include earlier update commits.

On Mondays and manual runs the job refreshes Home Assistant's container digest; if that fails, the digest stays as it was and the run goes on. It then updates the flake inputs in two groups:

- The server-only inputs in `SERVER_INPUTS` update first, with the Caddy plugin hash refreshed if necessary. They must pass the flake check and a Sparkle build.
- The remaining inputs update next. They must pass the flake check and builds of Sparkle, Camellya, and Kafka.

A group that fails is rolled back, and the other group's update still goes ahead. If anything changed, the job checks all systems again, builds Sparkle, including its guest runners, then Camellya and Kafka, and pushes one signed commit with the combined changes. A desktop that fails this last build does not hold the commit back, because accepted inputs were already built with it. The job compares the new lock file with the old one using the [check the servers run](../modules/nixos/nix/ci-lock-check.jq). A commit that fails it is still pushed, so that it can be [accepted](#server-upgrades). Sparxie and Silverwolf are evaluated but not built by the x86_64 Linux runner.

The run fails after pushing, and names the cause, when the digest or a group was rolled back, a desktop was not built, or the servers will refuse the commit. If the branch moved during the run, nothing is pushed and the run fails; run it again.

`CI_SIGNING_KEY` supplies the SSH signing key. The workflow uploads Sparkle to the `server` cache and the built desktops to the `desktop` cache with `ATTIC_TOKEN` before committing and pushing. A missing token or failed upload blocks the push. The temporary signing key and upload credential are removed when their steps finish.

The [validation workflow](../.forgejo/workflows/validate.yml) checks pushes to `main` and manual runs. It also checks that each `host.autoUpdate.ciPins` pattern matches exactly one line of its file. It reports problems after the push and does not hold back upgrades; a server that cannot build a commit keeps its current system and mails the failure. A host that pulls a commit the caches lack builds the missing parts itself; the next update run that changes something caches the systems again. Validation builds only uncached systems and uploads nothing. A new push to `main` cancels the older run. The update workflow pushes with the workflow token, which starts no other workflows, so its commits are checked only by its own run.

## Server upgrades

Sparkle and Sparxie check `origin/main` as described below, then reset `/persist/nix-config` to it. Sparkle's `origin` is Forgejo. Sparxie's is the GitHub mirror `https://github.com/LapineLunaire/nix-config`, so it deploys only what the mirror holds at upgrade time; the same signature checks apply. This discards uncommitted tracked changes and unpushed commits on the checked-out branch. Commit and push from Camellya, Kafka, or Silverwolf with its configured signing identity.

- `origin/main` must contain the last deployed commit, stored in `/var/lib/nixos-upgrade/deployed-rev` after each successful rebuild. A force push or rollback is refused. The first upgrade on a new host has no stored commit and skips this check.
- From the tip, commits signed with a `host.autoUpdate.ciSigners` key are walked back to a commit signed with a `host.autoUpdate.allowedSigners` key or the deployed commit. A signature from `allowedSigners` covers the commit's whole history.
- A CI commit must have one parent and change only flake input versions or text matching the patterns in `host.autoUpdate.ciPins`. Flake inputs keep their sources and dependency wiring, and their `lastModified` dates cannot go back. The check does not prove that a new revision is on the input's branch, and GitHub serves commits from forks through the parent repository, so `CI_SIGNING_KEY` can point an input at any code whose date is not earlier. Guard it like root access to the servers. File modes cannot change. Add new inputs with their lock entries in a signed commit. When the workflow starts refreshing another pinned value, add its file and pattern to `ciPins`.

After a deliberate force push, run `doas rm /var/lib/nixos-upgrade/deployed-rev` on each affected host to accept the rewritten history. The next upgrade still checks commit signatures and CI changes.

A dependency update that adds, removes, renames, or rewires lock entries makes the next CI commit fail this check, and the update run that pushed it fails with a note. Review that commit and push a signed commit on top, such as `git commit --allow-empty -S -m "Accept the flake update"`.

Sparxie reboots when the kernel, kernel modules, or initrd change. Sparkle restarts changed running guests; boot changes need a manual reboot and the pool passphrase. Failed upgrades mail the last 50 log lines. Upgrades and backups never overlap: an upgrade waits for a running backup, and a backup waits for a running upgrade and the reboot it may schedule. Commits pushed after the upgrade check wait for the next night. Desktop activation remains manual.

The 05:00 workflow prepares updates for the following day's upgrade.

Server upgrades do not wait for running jobs, so long or manual workflows can be interrupted. See [guest operations](guests.md#ci-jobs) for the container image and job storage.
