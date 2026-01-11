{inputs, ...}: {
  nix.settings = inputs.aagl.nixConfig;

  programs.honkers-railway-launcher.enable = true;
}
