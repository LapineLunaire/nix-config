# Guest operations

## Console and restart

Run on Sparkle:

```sh
doas microvm -s <name>
doas systemctl restart microvm@<name>
```

`microvm -s` opens a root shell over VSOCK, authenticated with Sparkle's SSH host key. A manual host switch installs new guest runners without restarting the guests; the nightly upgrade restarts changed running guests. The `deps` entries in `hosts/sparkle/guest-registry.nix` order startup but do not wait for the applications to become ready.

## Add a guest

1. Add its directory under `hosts/sparkle/guests/` and a unique index from 10 to 99 in `hosts/sparkle/guest-registry.nix`. Do not change existing indices, because they determine each guest's IP address, VSOCK CID, and hexadecimal MAC suffix.
2. Add web backends to `hosts/sparkle/guest-web.nix`, which also generates the DNS records and the firewall rules between proxy and the guest. Proxy serves a vhost for each backend that admits trusted clients and uptime-kuma. For other callers or a custom body, add an entry to `vmVhostOverrides` in `hosts/sparkle/guests/proxy/vhosts.nix`. Declare `microvmGuest.egress`, and add any other ingress to `hosts/sparkle/dmz-bridge.nix` and the guest firewall. See [network access](network.md).
3. For NFS, update `nfsClients` in `hosts/sparkle/guest-net.nix`, the guest's mount, and the vault guest's export.
4. Restore the guest's keys and state, or create its identity as root:

   ```sh
   mkdir -p /persist/vms/<name>/etc/ssh
   ssh-keygen -t ed25519 -N '' -f /persist/vms/<name>/etc/ssh/ssh_host_ed25519_key
   ```

   For SOPS, convert the public key with `ssh-to-age`, add the recipient and a creation rule to `.sops.yaml`, and encrypt the secrets for both the guest and Sparkle. Restore keys and state with their numeric owners. Put disk images under `/persist/volumes/<name>`, never inside a guest's writable share, where guest root could redirect them to another guest's image. Sparkle creates each image directory as `microvm:kvm` with mode `0750`. For secret value formats, see [restore identity and state](keys.md#restore-identity-and-state).

Stage new files with `git add` before evaluating or switching, because a Git-backed flake omits untracked files. Commit the guest, sign it with a key in `host.autoUpdate.allowedSigners`, and push it before the next nightly upgrade. The upgrade runs `git reset --hard` to `origin/main`, which also deletes staged files that are not committed.

## CI jobs

The ci-runner guest runs each `nixos` Forgejo Actions job in a fresh Docker container. [image.nix](../hosts/sparkle/guests/ci-runner/image.nix) builds the job image from locked Nixpkgs. The image is part of Sparkle's build and needs no registry. Its fixed `localhost/nix-ci:current` tag avoids re-registering the runner when the image changes.

The runner takes one job at a time, so a job can use all 8 CPUs, 20 GiB RAM, and the swap for large builds; other jobs queue. Nix runs three builds at once. Forgejo supersedes older validation pushes to the same branch, and the update workflow serializes updates to the same branch.

Jobs have separate Nix stores, databases, checkouts, and credentials, removed when they finish. Nix runs without a daemon or its build sandbox; Docker and the microVM provide isolation. Builds run as unprivileged `nixbld` users, so builders cannot create `/homeless-shelter`, which makes unsandboxed Nix refuse to build. Jobs are not privileged and get no host mounts or daemon sockets. They download or build paths absent from the image, using the [read-only cache token](secrets.md). Signing and publishing credentials come from Forgejo workflow secrets.

Before each start, including after a crash, the runner service removes all containers, volumes, and unused networks, loads the image, and removes the old untagged image. Docker in this guest must therefore only run CI jobs. Docker uses a 192 GiB XFS disk, with 32 GiB swap after zram. The disk images live in `/persist/volumes/ci-runner`. Check the guest with `systemctl status docker gitea-runner-sparkle`.

The guest itself mounts the host store read-only at `/nix/.ro-store` with a tmpfs upper layer at `/nix/.rw-store`. Do not garbage-collect inside the guest, because overlay whiteouts can hide host paths that later generations need. Job stores live in the containers, not in this overlay.

## Borg backup and recovery

Sparkle and Sparxie back up a snapshot of `/persist` and keep 7 daily, 4 weekly, and 3 monthly archives. Borg does not cover `/home` or the vault pool; `nixos-install` recreates `/nix`.

Sparkle's backup excludes:

- `/persist/volumes/`: the ci-runner Docker and swap images, and the homeassistant Docker and unifi Podman storage images.

Home Assistant's bind-mounted `/config` and UniFi's `/var/lib/unifi-os-server` stay in the backup. Preserve numeric owners when restoring.

The `borg-job-hetzner` helper reads the repository, passphrase, SSH key, and pinned host key from the SOPS secrets at runtime:

```sh
doas borg-job-hetzner list
doas borg-job-hetzner info ::<archive>
doas borg-job-hetzner check
```

The backup job does not create repositories. Initialize a new one with:

```sh
doas borg-job-hetzner init --encryption repokey-blake2
doas borg-job-hetzner key export :: ~/borg-key
```

The repository holds the only copy of the key. Store the exported key with the passphrase in the password manager, then run `doas rm ~/borg-key`.

Extract into a separate directory, stop the affected guest, then copy the selected state into `/persist`. Archive paths begin with `mnt/borg-snapshot/`. `--checksum` replaces files whose size and modification time happen to match, and `--delete` removes files missing from the archive:

```sh
mkdir -p ~/borg-restore
cd ~/borg-restore
doas borg-job-hetzner extract --numeric-ids ::<archive> mnt/borg-snapshot/vms/<name>
doas systemctl stop microvm@<name>
doas rsync -aHAX --numeric-ids --checksum --delete mnt/borg-snapshot/vms/<name>/ /persist/vms/<name>/
doas systemctl start microvm@<name>
cd ~
doas rm -rf ~/borg-restore
```

For a full host recovery, see [server recovery](recover-servers.md).

The job fails on Borg warnings as well as errors, and each failure mails the last 50 lines of the job log. Only a run that completes creation, pruning, and compaction touches `/var/lib/borgbackup/hetzner/last-success`. At 12:00 UTC, `borgbackup-freshness` mails when that file is missing or more than 24 hours old. To inspect the job:

```sh
doas systemctl status borgbackup-job-hetzner.timer borgbackup-job-hetzner.service borgbackup-freshness.timer
doas journalctl -u borgbackup-job-hetzner -n 50 --no-pager
```
