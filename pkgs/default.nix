# Custom packages, defined similarly to ones from nixpkgs.
# Build them with 'nix build .#example'.
pkgs: {
  bunny-web = pkgs.callPackage ./bunny-web {};
  tibia = pkgs.callPackage ./tibia {};
}
