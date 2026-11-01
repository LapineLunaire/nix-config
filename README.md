# nix-config

NixOS and nix-darwin configuration for Camellya, Kafka, Silverwolf, Sparkle, and Sparxie, including Sparkle’s 16 microVM guests.

## Quick start

Run from the host's checkout:

```sh
nh os switch .      # Camellya, Kafka, Sparkle, Sparxie
nh darwin switch .  # Silverwolf
```

Linux hosts use `/persist/nix-config`; Silverwolf uses `~/projects/nix-config`.

## Guides

- [Installation and recovery](docs/install.md)
- [Guest operations and backups](docs/guests.md)
- [Network access](docs/network.md)
- [Automated updates](docs/updates.md)
- [Shared secrets](docs/secrets.md)

## Configuration

The flake exports NixOS desktop and server profiles, a Darwin profile, and reusable NixOS modules. Desktop and server profiles live in `profiles/desktop/` and `profiles/server/`, with shared Attic credentials beside each `default.nix`. The server cache is enabled on Sparkle; ci-runner keeps its own token for both caches. Profiles keep simple settings in place and import modules for larger features.

NixOS modules are grouped by purpose under `modules/nixos/`: system settings, networking, services, programs, desktop settings, Nix maintenance, and microVMs. Shared NixOS and Darwin settings live under `modules/shared/`.

Each host imports its upstream modules, system profile, host configuration, and user configuration in that order. Hardware, networking, persistence, and secrets live with each host under `hosts/`.

Carmilla's entries share Home Manager programs. Camellya and Kafka use entries under `users/carmilla/hosts/` for per-system packages and settings. Both import the shared desktop configuration. Silverwolf shares application settings and also uses Homebrew for its macOS application list.

Camellya and Kafka run T3 Code as a Home Manager user service on port 3773, using the configured Codex and Claude Code packages. User lingering starts the server at boot and keeps it running after logout. The firewall restricts it to the same trusted subnets as SSH; Kafka also requires a trusted NetworkManager connection. Settings remain writable; a rebuild restores declared values.

The desktop app is a client of the server, and both use `~/.t3`. A rebuild keeps the app's local environment off because the server locks that directory.

Quit the app and switch from a normal terminal: package updates restart the service and interrupt its agents, and an open app can undo the setting when it closes. Pair the app once on each host with the token from `t3 pair`. Use the loopback address, because the LAN address in the printed link changes between networks:

```sh
t3code-desktop "t3code://pair?pairingUrl=http%3A%2F%2F127.0.0.1%3A3773%2Fpair%23token%3D<token>"
```

The app's native folder picker is off in this mode. Check the service with `systemctl --user status t3code` and its logs with `journalctl --user -u t3code`.

Camellya, Kafka, and Silverwolf use unstable packages and Home Manager; Sparkle, Sparxie, and the guests use stable packages. Each host sets its system and home state versions.

## Development

```sh
nix develop
alejandra .
```

The shell provides uutils, Alejandra, nixd, SOPS, and ssh-to-age on `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. Direnv can load it through `.envrc`.

Entering the shell enables the Git hook that checks staged Nix files with Alejandra before committing.

## Check changes

Stage new files before checking: Git-backed flakes omit untracked files.

```sh
nix fmt --no-write-lock-file -- --check .
nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
```

The second command evaluates all five host and 16 guest derivations, the formatter, development shells, and exported module definitions. It does not build or activate the systems.
