# Shared secrets

SOPS files group credentials by their readers. Every recipient can decrypt every secret in a file. A secret that several hosts read is stored once, in a file with all of them as recipients, so there are no copies that can drift. `.sops.yaml` defines recipients for new files; use `sops updatekeys -y <file>` to update an existing file after changing its recipients.

| File | Keys | Recipients |
|---|---|---|
| `users/carmilla/secrets.yaml` | `carmilla-password-hash` | Camellya, Kafka, Sparkle, Sparxie |
| `modules/nixos/nix/attic-client.yaml` | `attic-pull-token` | Camellya, Kafka, Sparkle, ci-runner |
| `hosts/sparkle/smtp.yaml` | `smtp-password` | Sparkle, Vault, Forgejo, Authelia, Vaultwarden |
| `hosts/sparkle/guests/attic/database.yaml` | `attic-db-password` | Sparkle, PostgreSQL, Attic |
| `hosts/sparkle/guests/authelia/database.yaml` | `authelia-db-password` | Sparkle, PostgreSQL, Authelia |
| `hosts/sparkle/guests/forgejo/database.yaml` | `forgejo-db-password` | Sparkle, PostgreSQL, Forgejo |
| `hosts/sparkle/guests/vaultwarden/database.yaml` | `vaultwarden-db-password` | Sparkle, PostgreSQL, Vaultwarden |

Create or edit a file with `sops <file>`. Values such as SMTP passwords, DNS tokens, and Attic tokens are plaintext inside the editor. Keys ending in `-hash` hold hashes: Carmilla's login password, the qBittorrent and Caddy basic-auth passwords, and Authelia's OIDC client secrets. Stage new encrypted files before checking the Git-backed flake.

Camellya, Kafka, Sparkle, and ci-runner share one Attic pull token, which needs read access to the `lune` cache and no write permissions. The Forgejo `ATTIC_TOKEN` secret needs read and push access to it. On ci-runner, SOPS renders a root-owned, mode 0400 netrc file that the runner mounts read-only at `/etc/nix/netrc` in every job. The token never enters the job environment, and build users cannot read the file. The image contains no credentials.

Sparkle and its applications read SMTP credentials from `hosts/sparkle/smtp.yaml`. Keep that credential valid for their configured SMTP account and sender. Sparxie's SMTP credential is in `hosts/sparxie/secrets.yaml`.

Each application's database password comes from the same file on both the application guest and PostgreSQL. Keep database passwords URL-safe where used in connection URLs. Updating the shared file restarts the password-setting unit on PostgreSQL and the affected application or its secret template. Guest updates must reach both systems; separate VM restarts can briefly leave their credentials out of sync.

Host-specific credentials live in `hosts/<host>/secrets.yaml`; guest application keys live in `hosts/sparkle/guests/<guest>/secrets.yaml`. For identity recovery, see [SSH identity and secrets](keys.md).
