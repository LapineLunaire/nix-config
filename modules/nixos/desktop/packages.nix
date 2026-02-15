{pkgs, ...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.sway = {
    enable = true;
    extraPackages = [];
  };

  xdg.portal.wlr = {
    enable = true;
    settings = {
      screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.rofi}/bin/rofi -dmenu -p 'Select screen to share'";
      };
    };
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  programs.nix-ld.enable = true;

  programs.gamemode.enable = true;
  programs.honkers-railway-launcher.enable = true;

  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };
}
