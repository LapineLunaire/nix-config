# nix-config

Nix configuration for camellya.

Run `nh os switch .` from the Linux host's checkout at `/persist/nix-config`.

Use `nix develop` for the development tools and staged formatting hook.

```sh
nix fmt --no-write-lock-file -- --check .
nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
```

Build a Linux host with `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
