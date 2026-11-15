# Install Camellya or Kafka

Boot an x86_64 NixOS installer in UEFI mode with Secure Boot enforcement disabled. Connect to the network, then run the commands as root in Bash. Replace `<repo>` with the repository URL. Set `host` to `camellya` or `kafka`; the commands below use it.

For recovery of an existing installation, follow [recovery](recover-desktop-profile.md).

| | Camellya | Kafka |
|---|---|---|
| `host` | `camellya` | `kafka` |
| EFI partition end (`efi_end`) | `2GiB` | `1GiB` |
| Btrfs label | `CAMELLYA` | `KAFKA` |
| Kernel CPU target | Zen 5 | Tiger Lake |
| Swap file `/persist/swapfile` | 16 GiB | 32 GiB |
| Host secrets file | `hosts/camellya/secrets.yaml` | none |

The kernel is built for the CPU in `host.kernel.cpu`. On other hardware, review `hosts/<host>/default.nix` and `hardware-configuration.nix`, and on Camellya also `displays.nix`.

NixOS creates the swap file on first boot with the size set by `host.swapFileSize` in `hosts/<host>/default.nix`. Kafka installs to a 256 GB internal SSD.

## 1. Partition and encrypt

**The following commands erase the selected disk.** Pick the internal SSD by model and serial from `/dev/disk/by-id`, and set `disk` to it. Keep the LUKS passphrase for recovery.

```sh
host=camellya # or kafka
efi_end=2GiB  # 1GiB on Kafka
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,PARTLABEL,MOUNTPOINTS
ls /dev/disk/by-id/nvme-*
disk=/dev/disk/by-id/<disk>
parted $disk -- mklabel gpt
parted $disk -- mkpart $host-efi fat32 1MiB $efi_end
parted $disk -- set 1 esp on
parted $disk -- mkpart $host-crypt $efi_end 100%
udevadm settle
mkfs.vfat -F32 /dev/disk/by-partlabel/$host-efi

cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/$host-crypt
cryptsetup open /dev/disk/by-partlabel/$host-crypt cryptroot
mkfs.btrfs -L ${host^^} /dev/mapper/cryptroot
mkdir -p /mnt
mount -o subvolid=5 /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@persist
btrfs subvolume create /mnt/@home
umount /mnt
```

`${host^^}` is the host name in capitals: `CAMELLYA` or `KAFKA`.

Keep the partition and subvolume names as shown; the hardware configuration uses them to mount the filesystems. GPT partition names allow 36 characters, so they carry the host name. FAT volume labels allow only 11 and are not used.

## 2. Mount

The commands use `host` from step 1; set it again in a new shell.

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount -o umask=0077 /dev/disk/by-partlabel/$host-efi /mnt/boot
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
2. [Restore or create Secure Boot keys and bind-mount persisted `/var/lib`](secure-boot.md#installer-signing-keys), using the host name as `<hostname>`. Lanzaboote needs that mount during installation, including when keys are restored.

## 5. Install and reboot

On Camellya:

```sh
nixos-install --no-root-passwd --flake /mnt/persist/nix-config#camellya
```

On Kafka, which has 16 GiB of RAM, limit the build jobs as `hosts/kafka/default.nix` does and keep temporary build files on disk instead of in the installer's memory:

```sh
install -d -m 0700 /mnt/nix/install-tmp
TMPDIR=/mnt/nix/install-tmp nixos-install --no-root-passwd --no-channel-copy \
  --max-jobs 2 --cores 4 --flake /mnt/persist/nix-config#kafka
rm -rf /mnt/nix/install-tmp
```

Then, on both:

```sh
chown -R 1000:100 /mnt/persist/nix-config
cd /
umount -R /mnt
cryptsetup close cryptroot
reboot
```

The checkout belongs to `carmilla:users` (UID 1000, GID 100). Root password login is locked, and root cannot log in over SSH.

Installation signs the boot entries. Leave Secure Boot enforcement disabled until the signing keys are enrolled; use the LUKS passphrase for the first boot. The boot-time passphrase prompt and console use Colemak. Plasma also offers the US layout.

Log in locally as `carmilla` using the password whose hash you stored in SOPS. On Kafka, reconnect Wi-Fi after installation.

## 6. After the first boot

1. [Enroll and verify Secure Boot](secure-boot.md#installed-system-enrollment), then [enroll TPM2 with a PIN](secure-boot.md#tpm2-enrollment) using `/dev/disk/by-partlabel/camellya-crypt` or `/dev/disk/by-partlabel/kafka-crypt`.
2. Restore the [YubiKey SSH and Git signing identity](keys.md#yubikey-ssh-and-git-signing).
3. [Set up T3 Code](t3-code.md#setup).
4. On Kafka, check the built-in display, Wi-Fi, audio, brightness keys, and suspend/resume before relying on the laptop.

Kafka accepts SSH and T3 Code connections from the trusted subnets only on the NetworkManager connections listed in `host.trustedConnections` in `hosts/kafka/default.nix`, which are the home Wi-Fi and the WireGuard VPN. A recreated connection gets a new UUID. Find it with `nmcli -t -f UUID,TYPE connection show` and update the list.

Later switches use `nh os switch .` from `/persist/nix-config`; see the [README quick start](../README.md#quick-start).

## Disk usage

```sh
doas btrfs filesystem usage /nix
```
