{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  options.myConfig.gaming.enable = lib.mkEnableOption "gaming support";

  config = lib.mkIf config.myConfig.gaming.enable {
    nix.settings = inputs.aagl.nixConfig;

    programs.honkers-railway-launcher.enable = true;
    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
    };

    environment.sessionVariables = {
      PROTON_ENABLE_WAYLAND = "1";
      PROTON_ENABLE_HDR = "1";
    };
  };
}
