# Nix settings shared by NixOS (modules/nixos/generic) and nix-darwin (modules/darwin.nix).
{
  inputs,
  lib,
  ...
}: let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  # Exclude nixpkgs - nixpkgs-flake.nix auto-registers the system's nixpkgs correctly per host.
  registryInputs = lib.removeAttrs flakeInputs ["nixpkgs"];
in {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      flake-registry = ""; # disable global registry, only use pinned inputs
    };
    channel.enable = false;
    # Pin nix.registry and nixPath to flake inputs
    # so `nix run nixpkgs#foo` and `<nixpkgs>` always resolve to the locked revision rather than fetching from the upstream registry.
    registry = lib.mapAttrs (_: flake: {inherit flake;}) registryInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
