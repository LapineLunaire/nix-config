# nix-config

## Hosts

| Host | Platform | Role |
|------|----------|------|
| camellya | x86_64-linux | Desktop |
| sparkle | x86_64-linux | Home server |
| sparxie | aarch64-linux | VPS |
| silverwolf | aarch64-darwin | MacBook |

sparkle additionally runs a fleet of microVMs (cloud-hypervisor via microvm.nix), one per service: postgres, authelia, forgejo, ci-runner, homeassistant, qbittorrent, vaultwarden, kavita, uptime-kuma, monitoring, pgadmin, and unifi. homeassistant owns the host's USB controller through VFIO passthrough for the Zigbee stick. Each VM is its own `nixosConfigurations` output, generated from `hosts/sparkle/microvms/vm-registry.nix`, and is what the CI eval step transitively checks through sparkle's toplevel.

Linux hosts use impermanence with tmpfs `/` - state persists only through explicitly declared paths. Secrets are sops-nix encrypted to each host's SSH ed25519 host key.

## Structure

```
hosts/          Per-host hardware, services, secrets, persistence declarations
  sparkle/microvms/
    vm-registry.nix   Central registry: name -> index (vsock CID, MAC/IP octet) and startup deps
    vm-identity.nix   Guest identity (hostname, MAC, static IP) derived from the registry
    vm-net.nix        Host and per-VM addresses on vm-br0, imported wherever a VM IP is needed
    network.nix       vm-br0 bridge and the default-drop forward chain with per-flow allowlists
    guest.nix         Shared VM guest baseline: security.nix hardening, virtiofs persistence, sops, node_exporter, sshd serving the root vsock console
    docker-common.nix Journald logging and weekly image prune for the container-based VMs
    vms/<name>/       Per-VM config.nix (+ sops.nix/secrets.yaml where needed)
  sparkle/dmz-net.nix          sparkle's addressing on the DMZ subnet, shared by the sfp0 config, DNS zones, and the git vhost ACL
  sparxie/wan-net.nix          sparxie's static Hetzner VPS addresses, used by its WAN config and ejabberd's TURN listener
modules/
  site.nix      Declares the site option namespace (trusted subnets, SMTP relay, ACME email, auto-update repo and signers, WireGuard tunnel); each system defines its own values at the host boundary
  darwin.nix    macOS system defaults, firewall, privacy settings
  nix-settings.nix  Nix registry and nixPath pinning shared by NixOS and nix-darwin
  nixos/
    generic/    Base NixOS: SSH, impermanence baseline, zram, chrony, polkit, the doas wheel rule; imports security.nix
    desktop/    KDE Plasma 6, Plasma Login Manager, PipeWire, fonts, Steam; imports the aagl module
    packages.nix        System-wide programs and packages (zsh, neovim, nh) imported by every host
    desktop-packages.nix  Desktop programs and packages (obs, steam, gamemode, nix-ld) imported by desktop hosts
    auto-update.nix     Daily signature-verified system.autoUpgrade, shared by sparkle and sparxie; sparxie reboots on kernel changes, sparkle overrides that off and restarts the microVM guests the switch changed
    borg-backup.nix     Parameterised Borg job to Hetzner from a ZFS snapshot of <pool>/persist
    caddy.nix           Caddy with ACME via Cloudflare DNS-01; also exposes the caddySecurityHeaders snippet spliced into every vhost
    ip-whitelist.nix              nftables veto table dropping traffic to given ports unless the source IP is in whitelist files read at runtime (sops secrets, kept out of the store); used for sparxie's SSH
    postgres-passwords.nix        Applies the sops-templated role passwords after postgres starts
    secureboot.nix Lanzaboote secure boot
    security.nix   Kernel, network, and account hardening shared by full hosts (via generic) and the microVM guests
    trusted-ssh-ingress.nix Closes the firewall's ssh port and accepts port 22 from site.trustedSubnets instead
    zfs-maintenance.nix Scrub, TRIM, auto-snapshot retention
users/carmilla/ The carmilla user (identity, ssh keys, wheel) plus its home-manager config (shell, git, neovim, SSH, desktop, plasma), imported by full hosts and darwin; microVM guests have no carmilla user
pkgs/           Custom derivations
mk-systems.nix  The mkServerSystem/mkDesktopSystem/mkMicrovmSystem/mkDarwinSystem builders, parameterised over the flake's inputs
overlays.nix    package overrides (ffmpeg unfree codecs, mpv/yt-dlp ffmpeg, discord, winbox4)
```

## Network layout

| Subnet | Role |
|--------|------|
| 10.28.16.0/24 | Management network (UniFi devices) |
| 10.28.32.0/23 | DMZ (sparkle at 10.28.32.25, CoreDNS) |
| 10.28.34.0/24 | sparkle VM bridge `vm-br0`; last octet is the vm-registry index, `.1` is the host |
| 10.28.64.0/24 | LAN clients |
| 10.28.96.0/24 | WireGuard VPN clients |
| 10.100.0.0/24 | Nox's LAN |
| 10.1.0.0/24 | Nox's WireGuard VPN clients |
| 10.73.212.0/31 | sparkle (`.0`) <-> sparxie (`.1`) WireGuard tunnel |

The four client subnets trusted to reach admin surfaces (both LANs and both WireGuard subnets) are declared as `site.trustedSubnets` and defined per system (sparkle, camellya, and the forgejo VM), feeding the Caddy vhost ACLs, the VM bridge forward policy, the sshd ingress on sparkle and camellya, forgejo's git-ssh ingress, Samba, and iperf3.

## Implementation notes

- qBittorrent on sparkle runs in a VPN-Confinement network namespace (ProtonVPN)
- Ghostty on macOS: installed via homebrew cask (no darwin support in nixpkgs), configured via home-manager with `package = null`
- KDE Plasma 6 on Wayland via Plasma Login Manager; user-level Plasma config managed by plasma-manager
- Console keymap is Colemak on desktop hosts

## Security model

Threat model is device theft, remote compromise of internet-facing services, and accidental key exposure - not insider attacks or multi-tenant isolation.

**Authentication**
- SSH: FIDO2 resident keys (`ed25519-sk`) only, no passwords, root login disabled; microVM guests instead permit key-only root login, authorized for sparkle's host key and reached over the vsock console
- Privilege escalation: `doas` (sudo disabled), wheel-only
- macOS uses Touch ID for sudo

**Secrets**
- sops-nix encrypted to each host's SSH ed25519 host key
- sparkle persists the host key on a ZFS native-encrypted dataset with an interactive boot passphrase, so disk theft is bounded by that passphrase
- camellya persists the host key on a LUKS2 volume (LVM + XFS) unlocked via TPM2 with a passphrase keyslot as fallback; a pulled disk is unreadable, but the whole stolen device boots to the login screen, so theft protection rests on the login password and the secure boot chain
- VM secrets are additionally encrypted to the sparkle host key so the host can rebuild any guest

**Network**
- Firewall enabled on every NixOS host; sparkle enforces a default-drop forward chain on the VM bridge with explicit per-flow allowlists, and the sparkle and camellya sshd accept only the trusted client subnets (on sparkle that excludes the VM bridge, DMZ, management network, and the sparxie tunnel)
- HTTP services on sparkle gated by per-vhost source-IP ACLs in Caddy with app-layer auth
- ACME runs as a separate lego unit (NixOS `security.acme`); Caddy reads issued certs off disk and never holds the Cloudflare DNS API token
- sparxie (the only public-internet host) exposes XMPP federation, Matrix federation (HTTPS + 8448), STUN/TURN, and HTTPS via Caddy; SSH is FIDO2-only with fail2ban and reachable only from the external source IPs whitelisted in the ssh-allowed-ips sops secrets (ip-whitelist.nix); a stale whitelist is recovered through the Hetzner console

**Boot integrity**
- Lanzaboote secure boot with sbctl-enrolled keys on camellya and sparkle
- sparkle's disk decryption is an interactive passphrase; camellya's is TPM2-sealed (`tpm2-device=auto`), trading passphrase-at-boot for reliance on secure boot integrity and the login screen
- Kernel hardening: KPTI, `slab_nomerge`, `page_alloc.shuffle`, `kptr_restrict=2`, `dmesg_restrict`, syncookies, strict rp_filter, ICMP redirects rejected
- AppArmor enabled, killing any unconfined confinables

**Update integrity**
- Commits are SSH-signed: interactively by a YubiKey resident key, and in CI by a dedicated Forgejo Actions key held as a repo secret
- sparkle and sparxie auto-upgrade daily at 03:00, refusing to build unless `origin/main` verifies against the trusted keys in each host's `site.autoUpdate.allowedSigners`; each then hard-resets its repo to that commit, which is what nix builds. sparxie reboots on kernel changes; sparkle skips reboot (its disk unlock is interactive) and restarts the microVM guests whose config the switch changed, since a host switch leaves them running their old one

**Backups**
- Borg (repokey-blake2 + zstd) to Hetzner Storage Box, preceded by a ZFS snapshot of `*/persist`
- Borg passphrase, SSH key, repo URL, and known_hosts all in sops

**Known limitations**
- sparxie has no disk encryption and the hypervisor is out of trust scope; its host key and on-disk sops content are readable by anyone with hypervisor-level access
- doas keeps environment, with a short auth-cookie persistence after the first prompt
- The Forgejo CI runner holds a signing key listed in `site.autoUpdate.allowedSigners` and can push to `main` for scheduled `flake.lock`, container-digest, and tibia-hash updates, which sparkle and sparxie then auto-deploy

## Bootstrapping a new host

### NixOS

Boot from a NixOS installer ISO, then:

**1. Partition**

```sh
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1GiB 100%

mkfs.vfat -F32 /dev/nvme0n1p1
```

**2a. Create ZFS pool and datasets** (sparkle layout)

```sh
zpool create -o ashift=12 -o autotrim=on \
  -O atime=off -O acltype=posixacl -O xattr=sa -O dnodesize=auto \
  -O normalization=formD -O compression=zstd \
  -O encryption=on -O keylocation=prompt -O keyformat=passphrase \
  -O mountpoint=none \
  <hostname> /dev/disk/by-id/<disk>-part2

zfs create <hostname>/nix
zfs create <hostname>/persist
zfs create <hostname>/home
```

Mark datasets for auto-snapshotting - `services.zfs.autoSnapshot` (modules/nixos/zfs-maintenance.nix) only snapshots datasets with the property set:

```sh
zfs set com.sun:auto-snapshot=true <hostname>/persist <hostname>/home
```

Without encryption: omit `-O encryption=on -O keylocation=prompt -O keyformat=passphrase`

With mirror: replace the vdev with `mirror /dev/disk/by-id/<disk1>-part2 /dev/disk/by-id/<disk2>-part2`

ZFS hosts also need a unique `networking.hostId` in the host config; generate one with `head -c4 /dev/urandom | od -An -tx4 | tr -d ' '`.

**2b. Create LUKS2 + LVM + XFS volumes** (camellya layout)

```sh
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

pvcreate /dev/mapper/cryptroot
vgcreate <hostname> /dev/mapper/cryptroot
lvcreate -L 200G -n nix <hostname>
lvcreate -L 100G -n persist <hostname>
lvcreate -l 100%FREE -n home <hostname>

mkfs.xfs /dev/<hostname>/nix
mkfs.xfs /dev/<hostname>/persist
mkfs.xfs /dev/<hostname>/home
```

TPM2 enrollment happens after first boot (step 7); the passphrase keyslot stays as fallback.

**3. Mount**

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount /dev/nvme0n1p1 /mnt/boot

# ZFS layout:
mount -t zfs -o zfsutil <hostname>/nix /mnt/nix
mount -t zfs -o zfsutil <hostname>/persist /mnt/persist
mount -t zfs -o zfsutil <hostname>/home /mnt/home

# LUKS/LVM layout:
mount -o noatime /dev/<hostname>/nix /mnt/nix
mount -o noatime /dev/<hostname>/persist /mnt/persist
mount -o noatime /dev/<hostname>/home /mnt/home
```

**4. Generate the SSH host key (required for sops)**

```sh
mkdir -p /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
```

**5. Register the host with sops**

Get the age public key derived from the SSH host key:

```sh
nix-shell -p ssh-to-age --run "ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub"
```

Add the output to `.sops.yaml` under a new `<hostname>_host` key, include it in the creation rules for `hosts/<hostname>/secrets.yaml`, then re-encrypt:

```sh
sops updatekeys hosts/<hostname>/secrets.yaml
```

**6. Clone the repo and install**

```sh
mkdir -p /mnt/persist/nix-config
git clone <repo> /mnt/persist/nix-config
nixos-install --flake /mnt/persist/nix-config#<hostname>
```

**7. First boot - Secure Boot hosts only** (camellya, sparkle)

After rebooting into the installed system:

```sh
sbctl create-keys
sbctl enroll-keys --microsoft
```

On camellya, enroll the TPM2 into the LUKS header after secure boot is enrolled and verified (`bootctl status`), since the seal binds to PCR 7:

```sh
systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2
```

---

### microVM (sparkle)

**1. Register the VM**

Pick a free index (10-99) and add the VM to `hosts/sparkle/microvms/vm-registry.nix`. The index becomes the vsock CID, the MAC suffix, and the IP `10.28.34.<index>`. List `deps` if it must start after another VM (e.g. postgres).

**2. Write the config**

Create `hosts/sparkle/microvms/vms/<name>/config.nix` with the VM's `microvm` resources; the virtiofs state share mapping `/persist/vms/<name>` to `/persist` comes from `vm-identity.nix`. If the host proxies the VM's web UI, list the port in `microvmGuest.hostIngressTCPPorts` (and add the Caddy vhost). Container-based VMs also need a dedicated XFS volume for `/var/lib/docker` (overlayfs cannot run on virtiofs) and an import of `docker-common.nix`.

**3. Create state and the guest host key on sparkle**

```sh
mkdir -p /persist/vms/<name>/etc/ssh
ssh-keygen -t ed25519 -N "" -f /persist/vms/<name>/etc/ssh/ssh_host_ed25519_key
```

**4. Secrets (if any)**

Convert the guest key (`ssh-to-age < /persist/vms/<name>/etc/ssh/ssh_host_ed25519_key.pub`), add it to `.sops.yaml` with a creation rule for `hosts/sparkle/microvms/vms/<name>/secrets.yaml` that also includes `sparkle_host` (so the host can rebuild the guest), then create the secrets file and a `sops.nix` importing it.

**5. Wire it into the flake and network**

- Extra flake-input modules (if needed): add to `extraModules` in `flake.nix`.
- Reverse proxy: add a vhost to `hosts/sparkle/services/proxy.nix`.
- DNS: the CNAME is generated from the Caddy vhost; bump the zone serial in `hosts/sparkle/services/coredns.nix`.
- Firewall: the VM's own ingress allowlist lives in its `config.nix`; VM-to-VM or VM-to-LAN flows need forward-chain rules in `hosts/sparkle/microvms/network.nix`.

Monitoring picks up the VM's node_exporter automatically from the registry; uptime-kuma probes are added manually in its UI.

---

### macOS (silverwolf)

nix-darwin manages Homebrew declaratively but cannot install it - Homebrew must be installed before Nix.

**1. Install Homebrew**

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Install Nix**

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

**3. Clone the repo**

```sh
git clone <repo> ~/projects/nix-config
```

**4. Bootstrap nix-darwin** (first run only - `nh` is not yet available)

```sh
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/projects/nix-config#silverwolf
```

**5. Subsequent rebuilds**

```sh
nh darwin switch ~/projects/nix-config
```

## Manual post-install steps

- Export FIDO2 resident SSH keys from YubiKey: `ssh-keygen -K` in `~/.ssh/`
- Create `~/Pictures/Screenshots` on macOS
- Grant App Management permission to the terminal emulator (System Settings > Privacy & Security > App Management)

## Usage

```sh
# NixOS
nh os switch .

# macOS
nh darwin switch .
```

### One-off package builds

To build a single package with overlays applied (e.g. to test an overlay change before a full rebuild):

```sh
nix build .\#nixosConfigurations.camellya.pkgs.<package>
```
