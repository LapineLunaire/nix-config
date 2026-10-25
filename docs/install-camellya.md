# Install Camellya

Boot an x86_64 NixOS installer in UEFI mode with Secure Boot enforcement disabled. Run installer commands as root in Bash. The kernel targets Zen 5; on other hardware, review `hosts/camellya/default.nix`, `hardware-configuration.nix`, and `displays.nix`.

Replace `<repo>` with the repository URL. For recovery of an existing installation, follow [Camellya recovery](recover-camellya.md).

## 1. Partition and encrypt

**The following commands erase the selected disk.** Pick it by model and serial from `/dev/disk/by-id`, and set `disk` to it. Keep the LUKS passphrase for recovery.

```sh
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,PARTLABEL,MOUNTPOINTS
ls /dev/disk/by-id/nvme-*
disk=/dev/disk/by-id/<disk>
parted $disk -- mklabel gpt
parted $disk -- mkpart camellya-efi fat32 1MiB 2GiB
parted $disk -- set 1 esp on
parted $disk -- mkpart camellya-crypt 2GiB 100%
udevadm settle
mkfs.vfat -F32 /dev/disk/by-partlabel/camellya-efi

cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/camellya-crypt
cryptsetup open /dev/disk/by-partlabel/camellya-crypt cryptroot
mkfs.btrfs -L CAMELLYA /dev/mapper/cryptroot
mkdir -p /mnt
mount -o subvolid=5 /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@persist
btrfs subvolume create /mnt/@home
umount /mnt
```

Keep the partition and subvolume names as shown; the hardware configuration uses them to mount the filesystems. GPT partition names allow 36 characters, so they carry the host name. FAT volume labels allow only 11 and are not used.

## 2. Mount

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount -o umask=0077 /dev/disk/by-partlabel/camellya-efi /mnt/boot
mount -o subvol=@nix,compress=zstd:3,noatime /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@persist,compress=zstd:3,noatime,nosuid,nodev /dev/mapper/cryptroot /mnt/persist
mount -o subvol=@home,compress=zstd:3,noatime,nosuid,nodev /dev/mapper/cryptroot /mnt/home
```

## 3. Checkout

```sh
git clone <repo> /mnt/persist/nix-config
cd /mnt/persist/nix-config
```

## 4. Prepare identity and signing keys

1. [Restore the SSH host key and complete the secrets](keys.md#host-identity-and-secrets). User creation needs the SOPS password hash before installation.
2. [Restore or create Secure Boot keys and bind-mount persisted `/var/lib`](secure-boot.md#installer-signing-keys). Lanzaboote needs that mount during installation, including when keys are restored.

## 5. Install and reboot

```sh
nixos-install --no-root-passwd --flake /mnt/persist/nix-config#camellya
chown -R 1000:100 /mnt/persist/nix-config
cd /
umount -R /mnt
cryptsetup close cryptroot
reboot
```

The checkout belongs to `carmilla:users` (UID 1000, GID 100). Root password login is locked, and root cannot log in over SSH. Log in locally as `carmilla` using the password whose hash you stored in SOPS.

Installation signs the boot entries. Leave Secure Boot enforcement disabled until the signing keys are enrolled; use the LUKS passphrase for the first boot.

Then [enroll Secure Boot keys and TPM2](secure-boot.md#installed-system-enrollment), and restore the [YubiKey SSH and Git signing identity](keys.md#yubikey-ssh-and-git-signing). For routine switches, see the [README quick start](../README.md#quick-start).

## Disk usage

```sh
doas btrfs filesystem usage /nix
```
