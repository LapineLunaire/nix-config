# SSH identity and secrets

## Host identity and secrets

Carmilla's Linux login password hash is `carmilla-password-hash` in `users/carmilla/secrets.yaml`, encrypted for Camellya, Kafka, Sparkle, and Sparxie. Create or edit it with `sops users/carmilla/secrets.yaml`. Stage the encrypted file before evaluating the flake. When replacing a host key, update this file's recipients with `sops updatekeys -y users/carmilla/secrets.yaml` using any remaining recipient's identity.

See [shared secrets](secrets.md) for the profile and service files. When replacing a host or guest key, update the recipients of every shared file that lists it, using an identity that can still decrypt the file. If no identity remains, recreate that file from the password manager. Encrypted values cannot be copied between SOPS files without decrypting and re-encrypting them.

Camellya and Kafka use the steps below. Run them as root in Bash from the installer's checkout at `/mnt/persist/nix-config`, with `<host>` as `camellya` or `kafka`.

Each host's SSH key pair decrypts the shared user and desktop profile secrets: `profiles/desktop/secrets.yaml` must contain `attic-pull-token`, and `users/carmilla/secrets.yaml` must contain `carmilla-password-hash`. Both files must include the host's key as a recipient. Camellya's key also decrypts `hosts/camellya/secrets.yaml`; Kafka has no host secrets file. Keep the private key outside Git and retain a secure backup.

Restore the key pair, replacing `<identity-directory>` with its backup location. The private key must be root-owned with mode `0600`. With the original key, existing secrets need no re-encryption.

```sh
install -d -m 0755 /mnt/persist/etc/ssh
install -m 0600 <identity-directory>/ssh_host_ed25519_key /mnt/persist/etc/ssh/
install -m 0644 <identity-directory>/ssh_host_ed25519_key.pub /mnt/persist/etc/ssh/
```

### If the SSH key is lost

If no backup exists, generate a key in the installer and print its age recipient:

```sh
install -d -m 0755 /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N '' -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#ssh-to-age \
  -c ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

The other host is a recipient of both shared files and re-encrypts them. On it, set `<host>_host` in `.sops.yaml` to the printed recipient, then re-encrypt both files with the `sops` alias:

```sh
sops updatekeys -y users/carmilla/secrets.yaml
sops updatekeys -y profiles/desktop/secrets.yaml
```

Commit and push the three files, then run `git pull` in the installer's checkout before installing. User creation needs the shared password hash. If the other host is unavailable, re-encrypt `users/carmilla/secrets.yaml` on Sparkle or Sparxie, which are also its recipients. Only Camellya and Kafka can decrypt `profiles/desktop/secrets.yaml`; without one, recreate it from the password manager. The installed `sops` alias is not available in the installer.

On Camellya, the host key is the only recipient of the host secrets, so a new key cannot decrypt the existing file. Recreate the file with the keys `samba-username` and `samba-password`, taking the values from the password manager:

```sh
rm hosts/camellya/secrets.yaml
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sops \
  -c sops hosts/camellya/secrets.yaml
```

Return to [installation](install-desktop-profile.md#4-prepare-identity-and-signing-keys) or [recovery](recover-desktop-profile.md#reinstall-from-the-installer).

On the installed system, the `sops` shell alias derives the age identity from the root-owned SSH host key through doas.

## Restore identity and state

Run these steps as root in Bash from the installer's checkout at `/mnt/persist/nix-config`.

Restore the host's SSH key pair to `/mnt/persist/etc/ssh/` and keep the private key root-owned with mode `0600`. With the original key, existing secrets need no changes. To create a new identity instead:

```sh
mkdir -p /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N '' -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs-stable#ssh-to-age \
  -c ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

Set `<hostname>_host` in `.sops.yaml` to the new age recipient. Use the old SSH host private key to re-encrypt the host secrets, replacing `<old-private-key>` with its file path:

```sh
SOPS_AGE_KEY_CMD='ssh-to-age -private-key -i <old-private-key>' \
  nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs-stable#sops nixpkgs-stable#ssh-to-age \
  -c sops updatekeys -y hosts/<hostname>/secrets.yaml
```

For a new Sparkle identity, set the new SSH public key in `hosts/sparkle/console-key.nix`, and repeat the command for each guest secret file whose creation rule includes `sparkle_host`, using either the old Sparkle key or that guest's key. If the old host key is lost, recreate `hosts/<hostname>/secrets.yaml` from the password manager with every secret that the host's configuration declares. If a guest file has neither key, recreate it too.

Restore guest keys and application state under `/mnt/persist/vms/` before the first boot. For a fresh Sparkle installation, create each guest's SSH key as in [guest provisioning](guests.md#add-a-guest), using `/mnt/persist/vms/<name>/etc/ssh/` in the installer. For guests with SOPS files, update their `vm_*` recipients in `.sops.yaml` and re-encrypt their secret files; both the guest and Sparkle must remain recipients.

Keep passwords and values inserted into configuration templates on one line. File secrets, such as SSH private keys and WireGuard configurations, keep their required multiline format. Follow each application's quoting rules, including Authelia's single-quoted YAML and ejabberd's block scalars. The Attic and Vaultwarden database passwords must be URL-safe, for example `openssl rand -hex 32`. Rotate an application's database password and the matching PostgreSQL role secret together.

Return to [installation](install-servers.md#3-prepare-identity-and-signing-keys) or [server recovery](recover-servers.md). On an installed host, the `sops` shell alias derives the age identity from the SSH host key through doas; that alias is unavailable in the installer.

## YubiKey SSH and Git signing

Camellya, Kafka, and Silverwolf configure this identity for SSH and Git signing.

Run `ssh-keygen -K` in a separate private directory for each YubiKey. Match the downloaded public key against `users/carmilla/ssh-keys.nix`, then move the selected key pair to:

```text
~/.ssh/id_ed25519_sk_rk_carmilla
~/.ssh/id_ed25519_sk_rk_carmilla.pub
```
