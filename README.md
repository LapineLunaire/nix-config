# nix-config

## Hosts

| Host | Platform | Role |
|------|----------|------|
| camellya | x86_64-linux | Desktop |
| sparkle | x86_64-linux | Home server |
| sparxie | aarch64-linux | VPS |
| silverwolf | aarch64-darwin | MacBook |

Linux hosts use impermanence with tmpfs `/` — state persists only through explicitly declared paths. Secrets are sops-nix encrypted to each host's SSH ed25519 host key.

## Structure

```
hosts/          Per-host hardware, services, secrets, persistence declarations
modules/
  darwin/       macOS system defaults, firewall, privacy settings
  nixos/
    generic/    Base NixOS: kernel hardening, SSH, ZFS, zram, chrony
    desktop/    Hyprland, PipeWire, fonts, Stylix theming, Steam
    secureboot/ Lanzaboote secure boot
users/carmilla/ home-manager: shell, git, neovim, SSH, desktop environment
pkgs/           Custom derivations
overlays/       ffmpeg unfree codecs, protonmail-desktop X11 ozone workaround
```

## Implementation notes

- qBittorrent on sparkle runs in a VPN-Confinement network namespace (ProtonVPN)
- Ghostty on macOS: installed via homebrew cask (no darwin support in nixpkgs), configured via home-manager with `package = null`
- Hyprland mod key is ALT with remapped macOS-style shortcuts (ALT+C/V → CTRL+C/V via `sendshortcut`)
- protonmail-desktop overlay forces X11 ozone platform on Linux to avoid Wayland crashes
- Console keymap is Colemak on all Linux hosts

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

**2. Create ZFS pool and datasets**

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

Without encryption: omit `-O encryption=on -O keylocation=prompt -O keyformat=passphrase`

With mirror: replace the vdev with `mirror /dev/disk/by-id/<disk1>-part2 /dev/disk/by-id/<disk2>-part2`

**3. Mount**

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount /dev/nvme0n1p1 /mnt/boot
mount -t zfs -o zfsutil <hostname>/nix /mnt/nix
mount -t zfs -o zfsutil <hostname>/persist /mnt/persist
mount -t zfs -o zfsutil <hostname>/home /mnt/home
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

**7. First boot — Secure Boot hosts only** (camellya, sparkle)

After rebooting into the installed system:

```sh
sbctl create-keys
sbctl enroll-keys --microsoft
```

---

### macOS (silverwolf)

nix-darwin manages Homebrew declaratively but cannot install it — Homebrew must be installed before Nix.

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

**4. Bootstrap nix-darwin** (first run only — `nh` is not yet available)

```sh
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/projects/nix-config#silverwolf
```

**5. Subsequent rebuilds**

```sh
nh darwin switch ~/projects/nix-config
```

## Manual post-install steps

- Place wallpapers in `~/pictures/wallpapers/` for the random wallpaper script to pick them up
- Export FIDO2 resident SSH keys from YubiKey: `ssh-keygen -K` in `~/.ssh/`
- Create `~/Pictures/Screenshots` on macOS
- Grant App Management permission to the terminal emulator (System Settings → Privacy & Security → App Management)

## Usage

```sh
# NixOS
nh os switch .

# macOS
nh darwin switch .
```
