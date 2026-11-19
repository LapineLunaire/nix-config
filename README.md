# nix-config

NixOS and nix-darwin configuration for Camellya, Kafka, Silverwolf, Sparkle, and Sparxie, including Sparkle’s 15 microVM guests.

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
- [T3 Code](docs/t3-code.md)

## Configuration

The flake exports NixOS desktop and server profiles, a Darwin profile, and reusable NixOS modules. Desktop and server profiles live in `profiles/desktop/` and `profiles/server/`. Both build on the NixOS base in `profiles/nixos.nix`. Camellya, Kafka, Sparkle, and ci-runner pull from one Attic cache, `lune`, set in `modules/nixos/nix/attic-client.nix`, with their shared pull token beside it. Profiles keep simple settings in place and import modules for larger features.

NixOS modules are grouped by purpose under `modules/nixos/`: system settings, networking, services, programs, desktop settings, Nix maintenance, and microVMs. Shared NixOS and Darwin settings live under `modules/shared/`.

Packages from this repository live under `pkgs/`. The desktop and server profiles add them to `pkgs` with the `additions` overlay in `overlays/`.

`flake.nix` builds each desktop with `mkDesktop` and each server with `mkServer`, both through `mkHost`, from upstream modules, a system profile, the host's directory, and user configuration. It sets the trusted subnets for every NixOS system and the checkout at `/persist/nix-config` for every Linux host. Hardware, networking, secrets, and per-host user settings live with each host under `hosts/`; the trusted client subnets are in `hosts/trusted-subnets.nix`. `flake.nix` imports these shared data files once, as `sharedData`, and passes them to every NixOS system as module arguments; modules take them as arguments rather than importing the files.

Carmilla's entries share Home Manager programs. Camellya and Kafka share `users/carmilla/desktop.nix` and set their own packages and wallpapers in `hosts/<host>/default.nix`. Silverwolf shares application settings and also uses Homebrew for its macOS application list.

Camellya and Kafka run the T3 Code server as the separate `t3` user, so coding agents cannot read Carmilla's home, use doas, or reach her YubiKey. Carmilla's desktop app is its client. Agents commit in `t3`'s own clone. Carmilla pulls and signs each commit with `t3-pull`, onto the default branch or onto a pull request's branch, then pushes with Git, after one pull or several. See [T3 Code](docs/t3-code.md).

Every host and guest uses the same inputs, with nixpkgs from the `staging-26.11` branch. Home Manager and nixvim follow their development branches, since they have no 26.11 branches yet. Each host sets its system and home state versions.

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

The second command evaluates all five host and 15 guest derivations, the formatter, development shells, and exported module definitions. It does not build or activate the systems.
