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

    fonts = {
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          autohint = false;
          style = "slight";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
        defaultFonts = {
          monospace = ["JetBrainsMono Nerd Font" "Noto Sans Mono CJK JP"];
          sansSerif = ["Noto Sans" "Noto Sans CJK JP"];
          serif = ["Noto Serif" "Noto Serif CJK JP"];
          emoji = ["Noto Color Emoji"];
        };
      };
    };
  };
}
