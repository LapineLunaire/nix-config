{
  inputs,
  pkgs,
  ...
}: {
  nix.settings = inputs.aagl.nixConfig;
  programs.honkers-railway-launcher.enable = true;

  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };
  programs.gamemode.enable = true;

  environment.sessionVariables = {
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
  };
}
