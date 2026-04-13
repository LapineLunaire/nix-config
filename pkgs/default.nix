# Custom packages, defined similarly to ones from nixpkgs.
# Build them with 'nix build .#example'.
pkgs: {
  elysia = pkgs.callPackage ./elysia {};
  bunny-web = pkgs.callPackage ./bunny-web {};
  pam_oo7 = pkgs.callPackage ./pam_oo7 {};
  tibia = pkgs.callPackage ./tibia {};
}
