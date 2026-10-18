# nix-config

Nix configuration for camellya, kafka, sparkle, sparxie, silverwolf.

Run `nh os switch .` from the Linux host's checkout at `/persist/nix-config`.
Run `nh darwin switch .` from Silverwolf's checkout.

Use `nix develop` for the development tools and staged formatting hook.

```sh
nix fmt --no-write-lock-file -- --check .
nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
```

Build a Linux host with `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
