# Custom packages, defined similarly to ones from nixpkgs.
# Build them with 'nix build .#example'.
pkgs: {
  elysia = pkgs.callPackage ./elysia {};
}
