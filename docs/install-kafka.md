# Install Kafka

Boot an x86_64 NixOS installer in UEFI mode with Secure Boot enforcement disabled. Connect to the network, then run the commands as root in Bash. Replace `<repo>` with the repository URL. For an existing installation, use [recovery](#recovery).

## 1. Partition and encrypt

**The following commands erase the selected disk.** Check the model and size with `lsblk`; substitute the actual internal SSD if it is not `/dev/nvme0n1`. Keep the LUKS passphrase for recovery.

```sh
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart kafka-crypt 1GiB 100%
mkfs.vfat -F32 -n KAFKA-EFI /dev/nvme0n1p1

cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot
mkfs.btrfs -L KAFKA /dev/mapper/cryptroot
mkdir -p /mnt
mount -o subvolid=5 /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@persist
btrfs subvolume create /mnt/@home
umount /mnt
```

Keep the labels and subvolume names as shown; the hardware configuration uses them to mount the filesystems.

## 2. Mount and clone

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount -o umask=0077 /dev/disk/by-label/KAFKA-EFI /mnt/boot
mount -o subvol=@nix,compress=zstd:3,noatime /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@persist,compress=zstd:3,noatime,nosuid,nodev /dev/mapper/cryptroot /mnt/persist
mount -o subvol=@home,compress=zstd:3,noatime,nosuid,nodev /dev/mapper/cryptroot /mnt/home
git clone <repo> /mnt/persist/nix-config
cd /mnt/persist/nix-config
```

## 3. Restore identity and signing keys

Restore Kafka's SSH key pair, which decrypts `hosts/kafka/secrets.yaml`. Replace `<identity-directory>` with its backup location:

```sh
install -d -m 0755 /mnt/persist/etc/ssh
install -m 0600 <identity-directory>/ssh_host_ed25519_key /mnt/persist/etc/ssh/
install -m 0644 <identity-directory>/ssh_host_ed25519_key.pub /mnt/persist/etc/ssh/
```

The encrypted file must contain `carmilla-password-hash` and `attic-pull-token`. Keep the private key outside Git and retain a secure backup. If the key is lost, generate a replacement, update Kafka's recipient in `.sops.yaml`, and recreate the encrypted secrets before installation.

[Restore or create Secure Boot keys and bind-mount persisted `/var/lib`](secure-boot.md#installer-signing-keys), using `kafka` as the hostname.

## 4. Install and reboot

```sh
install -d -m 0700 /mnt/nix/install-tmp
TMPDIR=/mnt/nix/install-tmp nixos-install --no-root-passwd --no-channel-copy \
  --max-jobs 2 --cores 4 --flake /mnt/persist/nix-config#kafka
rm -rf /mnt/nix/install-tmp
chown -R 1000:100 /mnt/persist/nix-config
cd /
umount -R /mnt
cryptsetup close cryptroot
reboot
```

Use the LUKS passphrase for the first boot and log in as `carmilla` with the password stored in SOPS. Reconnect Wi-Fi after installation.

The boot-time passphrase prompt and console use Colemak. Plasma also offers the US layout.

[Enroll and verify Secure Boot](secure-boot.md#installed-system-enrollment), then [enroll TPM2 with a PIN](secure-boot.md#tpm2-enrollment) using `/dev/disk/by-partlabel/kafka-crypt`. Restore the [YubiKey SSH and Git signing identity](keys.md#yubikey-ssh-and-git-signing).

Check the built-in display, Wi-Fi, audio, brightness keys, and suspend/resume before relying on the laptop. Later switches use `nh os switch .` from `/persist/nix-config`.

## Disk usage

```sh
doas btrfs filesystem usage /nix
```

## Recovery

Boot the installer with Secure Boot temporarily disabled. **Skip partitioning, formatting, and subvolume creation.** Unlock the existing disk:

```sh
cryptsetup open /dev/disk/by-partlabel/kafka-crypt cryptroot
```

Run the [mount commands](#2-mount-and-clone), reuse the existing checkout, and restore keys only if needed. Prepare the [Secure Boot bind mount](secure-boot.md#installer-signing-keys), then [reinstall](#4-install-and-reboot). Re-enable Secure Boot enforcement and verify it after boot.

Keep backups of `/home`, the needed `/persist` state, the SSH host key, and `/var/lib/sbctl`. Keep the LUKS passphrase and TPM PIN in the password manager.
