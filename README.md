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
