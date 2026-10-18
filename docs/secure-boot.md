# Secure Boot and TPM2

Camellya, Kafka, and Sparkle use Lanzaboote. Sparxie uses systemd-boot without Secure Boot enrollment.

## Installer signing keys

Run as root in Bash from the installer's checkout at `/mnt/persist/nix-config`.

Restore `/var/lib/sbctl` into `/mnt/persist/var/lib/sbctl`, or create new keys as shown next. Always bind-mount the persisted `/var/lib` into the target, because Lanzaboote needs `/var/lib/sbctl` during installation.

```sh
install -d -m 0700 /mnt/persist/var/lib/sbctl
mkdir -p /mnt/var/lib
mount --bind /mnt/persist/var/lib /mnt/var/lib
```

For new keys only, create them in the persisted directory. Replace `<hostname>` with `camellya`, `kafka`, or `sparkle` to use that host’s pinned sbctl package. The temporary config sets [sbctl's `keydir` and `guid`](https://github.com/Foxboron/sbctl/blob/0.18/docs/sbctl.conf.5.txt):

```sh
cat > /tmp/sbctl-install.yaml <<'EOF'
keydir: /mnt/persist/var/lib/sbctl/keys
guid: /mnt/persist/var/lib/sbctl/GUID
EOF
nix --extra-experimental-features 'nix-command flakes' shell '.#nixosConfigurations.<hostname>.pkgs.sbctl' \
  -c sbctl --config /tmp/sbctl-install.yaml create-keys
```

Return to [Camellya installation](install-camellya.md#5-install-and-reboot), [server installation](install-servers.md#4-install-and-export), or the relevant [recovery guide](install.md). Keep Secure Boot enforcement disabled until the signing keys are enrolled.

## Installed system enrollment

For new signing keys, enter firmware Setup Mode, preserving `dbx`, then boot the installed system. Follow the [Lanzaboote firmware guide](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html).

```sh
doas sbctl status
doas sbctl verify
doas sbctl enroll-keys --microsoft
```

`sbctl verify` lists Lanzaboote's `kernel-*.efi` files under `EFI/nixos` as unsigned, which is expected. Skip enrollment if restored keys are already enrolled. Enable enforcement in firmware, reboot, and confirm `bootctl status` reports Secure Boot as `enabled (user)` or `enabled (deployed)`.

Sparkle uses its ZFS pool passphrase at boot and needs no LUKS enrollment.

## TPM2 enrollment

Only after verifying Secure Boot, test the LUKS recovery passphrase and enroll TPM2 with a PIN. The commands below use Camellya's disk; for Kafka, replace `/dev/nvme0n1p2` with `/dev/disk/by-partlabel/kafka-crypt`:

```sh
doas cryptsetup open --test-passphrase /dev/nvme0n1p2
doas systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes --wipe-slot=tpm2 /dev/nvme0n1p2
```

This replaces old TPM tokens while retaining password slots. Reboot and confirm the PIN prompt. Rebuilds do not enroll LUKS tokens. PCR 7 records the Secure Boot state and the certificates that authorized the boot images; it does not measure the kernel, initrd, or command line. Keep the PIN and recovery passphrase. See `man systemd-cryptenroll` on the installed host for its enrollment reference.
