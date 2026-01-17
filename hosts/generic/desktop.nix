{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.hostConfig.desktop.enable {
    programs.sway = {
      enable = true;
      extraPackages = [];
    };

    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    programs.gamemode.enable = true;
    programs.honkers-railway-launcher.enable = true;

    programs.steam = {
      enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
    };

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
  };
}
