# Install Camellya

Boot an x86_64 NixOS installer in UEFI mode with Secure Boot enforcement disabled. Run installer commands as root in Bash. The kernel targets Zen 5; on other hardware, review `hosts/camellya/default.nix`, `hardware-configuration.nix`, and `displays.nix`.

Replace `<repo>` with the repository URL. For recovery of an existing installation, follow [Camellya recovery](recover-camellya.md).

## 1. Create the disk layout

These commands erase the disk. Confirm `/dev/nvme0n1` with `lsblk` before continuing, and keep the LUKS passphrase for recovery. The 200G and 100G volume sizes are examples; adjust them and leave space for `/home`.

```sh
lsblk
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1GiB 100%
mkfs.vfat -F32 /dev/nvme0n1p1

cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot
pvcreate /dev/mapper/cryptroot
vgcreate camellya /dev/mapper/cryptroot
lvcreate -L 200G -n nix camellya
lvcreate -L 100G -n persist camellya
lvcreate -l 100%FREE -n home camellya
mkfs.xfs /dev/camellya/nix
mkfs.xfs /dev/camellya/persist
mkfs.xfs /dev/camellya/home
```

## 2. Mount

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot
mount -o noatime /dev/camellya/nix /mnt/nix
mount -o noatime,nosuid,nodev /dev/camellya/persist /mnt/persist
mount -o noatime,nosuid,nodev /dev/camellya/home /mnt/home
```

## 3. Checkout and UUIDs

```sh
git clone <repo> /mnt/persist/nix-config
cd /mnt/persist/nix-config
blkid /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/camellya/nix /dev/camellya/persist /dev/camellya/home
```

Replace all five `by-uuid` values in `hosts/camellya/hardware-configuration.nix`: EFI, LUKS, `/nix`, `/persist`, `/home`. Formatting creates new UUIDs. Preserve the tmpfs root, `neededForBoot`, mount options, and hardware settings.

## 4. Prepare identity and signing keys

1. [Restore the SSH host key and complete the secrets](keys.md#host-identity-and-secrets). User creation needs the SOPS password hash before installation.
2. [Restore or create Secure Boot keys and bind-mount persisted `/var/lib`](secure-boot.md#installer-signing-keys). Lanzaboote needs that mount during installation, including when keys are restored.

## 5. Install and reboot

```sh
nixos-install --no-root-passwd --flake /mnt/persist/nix-config#camellya
chown -R 1000:100 /mnt/persist/nix-config
cd /
umount -R /mnt
vgchange -an camellya
cryptsetup close cryptroot
reboot
```

The checkout belongs to `carmilla:users` (UID 1000, GID 100). Root password login is locked, and root cannot log in over SSH. Log in locally as `carmilla` using the password whose hash you stored in SOPS.

Installation signs the boot entries. Leave Secure Boot enforcement disabled until the signing keys are enrolled; use the LUKS passphrase for the first boot.

Then [enroll Secure Boot keys and TPM2](secure-boot.md#installed-system-enrollment), and restore the [YubiKey SSH and Git signing identity](keys.md#yubikey-ssh-and-git-signing). For routine switches, see the [README quick start](../README.md#quick-start).
