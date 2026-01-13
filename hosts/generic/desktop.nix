{
  config,
  lib,
  ...
}: {
  options.hostConfig.desktop.enable = lib.mkEnableOption "desktop environment support";

  config = lib.mkIf config.hostConfig.desktop.enable {
    programs.sway = {
      enable = true;
      extraPackages = [];
    };

    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    # Required for Home Manager XDG portal integration
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
  };
}
