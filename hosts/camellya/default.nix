{pkgs, ...}: {
  imports = [
    ../generic
    ./hardware-configuration.nix
    ./persistence.nix
  ];

  hostConfig.desktop.enable = true;

  home-manager.users.lapine = {
    userConfig.desktop.enable = true;
    userConfig.nixd.enable = true;

    wayland.windowManager.sway.config.output."DP-2" = {
      mode = "2560x1440@165.080Hz";
      allow_tearing = "yes";
    };
  };

  networking = {
    hostName = "camellya";
    hostId = "0d339030";
    networkmanager.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = ["amd_pstate=active"];
    zfs.package = pkgs.zfs_unstable;
  };

  system.stateVersion = "25.11";
}
