{pkgs, ...}: {
  imports = [
    ../generic
    ./hardware-configuration.nix
    ./persistence.nix
  ];

  hostConfig.desktop.enable = false;

  home-manager.users.lapine = {
    userConfig.desktop.enable = false;
    userConfig.nixd.enable = true;
  };

  networking = {
    hostName = "sparkle";
    hostId = "00000000";
    networkmanager.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  system.stateVersion = "25.11";
}
