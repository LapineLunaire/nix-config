# Shared secrets

SOPS files group credentials by their readers. Every recipient can decrypt every secret in a file. `.sops.yaml` defines recipients for new files; use `sops updatekeys -y <file>` to update an existing file after changing its recipients.

| File | Keys | Recipients |
|---|---|---|
| `users/carmilla/secrets.yaml` | `carmilla-password-hash` | Camellya, Kafka, Sparkle, Sparxie |
| `profiles/desktop/secrets.yaml` | `attic-pull-token` | Camellya, Kafka |
| `profiles/server/secrets.yaml` | `attic-pull-token` | Sparkle |
| `hosts/sparkle/smtp.yaml` | `smtp-password` | Sparkle, Vault, Forgejo, Authelia, Vaultwarden |
| `hosts/sparkle/lunaire-moe-dns.yaml` | `lunaire-moe-dns-api-token` | Sparkle, Proxy, UniFi |
| `hosts/sparkle/guests/attic/database.yaml` | `attic-db-password` | Sparkle, PostgreSQL, Attic |
| `hosts/sparkle/guests/authelia/database.yaml` | `authelia-db-password` | Sparkle, PostgreSQL, Authelia |
| `hosts/sparkle/guests/forgejo/database.yaml` | `forgejo-db-password` | Sparkle, PostgreSQL, Forgejo |
| `hosts/sparkle/guests/vaultwarden/database.yaml` | `vaultwarden-db-password` | Sparkle, PostgreSQL, Vaultwarden |

Create or edit a file with `sops <file>`. Values such as SMTP passwords, DNS tokens, and Attic tokens are plaintext inside the editor; only the login password uses a hash. Stage new encrypted files before checking the Git-backed flake.

Desktop and server Attic tokens need read access to their respective caches. ci-runner uses its own `attic-pull-token` in its guest secrets file, with read access to both caches and no write permissions. Every job receives this token as `ATTIC_PULL_TOKEN`; the `configure-nix` action writes its own netrc file. Nix uses one netrc entry for `cache.lunaire.moe`, so jobs do not select separate credentials by cache URL. The image contains no credentials.

Sparkle's applications read the shared SMTP value through their existing runtime secret names. Keep that credential valid for their configured SMTP account and sender. Sparxie's SMTP credential stays in its host secrets file.

Each application's database password comes from the same file on both the application guest and PostgreSQL. Keep database passwords URL-safe where used in connection URLs. Updating the shared file restarts the password-setting unit on PostgreSQL and the affected application or its secret template. Guest updates must reach both systems; separate VM restarts can briefly leave their credentials out of sync.

Host-specific credentials and application keys remain in their existing files. For identity recovery, see [SSH identity and secrets](keys.md).
