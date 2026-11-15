# Recover Camellya or Kafka

## TPM unlock failure

Use the LUKS passphrase. Once Secure Boot is verified again, repeat [TPM enrollment](secure-boot.md#tpm2-enrollment).

## Reinstall from the installer

Boot an x86_64 NixOS installer in UEFI mode with Secure Boot temporarily disabled. Run as root in Bash. **Skip all partitioning, formatting, and subvolume creation.**

Set `host` to `camellya` or `kafka`, and unlock the existing disk:

```sh
host=camellya # or kafka
cryptsetup open /dev/disk/by-partlabel/$host-crypt cryptroot
```

1. [Mount the existing subvolumes](install-desktop-profile.md#2-mount).
2. Reuse `/mnt/persist/nix-config`; change into that checkout.
3. [Restore the SSH host key and secrets](keys.md#host-identity-and-secrets) if needed. The original key decrypts existing secrets without re-encryption.
4. [Restore Secure Boot keys and bind-mount persisted `/var/lib`](secure-boot.md#installer-signing-keys) before reinstalling.
5. [Reinstall and reboot](install-desktop-profile.md#5-install-and-reboot).
6. Re-enable Secure Boot enforcement and [verify it](secure-boot.md#installed-system-enrollment).

## Lost SSH host key

Create a new key and update the SOPS files as described in [If the SSH key is lost](keys.md#if-the-ssh-key-is-lost). The other host is a recipient of both shared files and re-encrypts them for the new key. Camellya also loses its host secrets, which must be recreated from the password manager. Kafka has no host secrets file.

## Backups for recovery

Keep secure copies of `/home`, the needed [`/persist` data](../modules/nixos/system/persistence.nix), the SSH host key, and `/var/lib/sbctl`. Persistence alone is not a backup. Keep secret values, the TPM PIN, and the LUKS recovery passphrase in the password manager.
