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
