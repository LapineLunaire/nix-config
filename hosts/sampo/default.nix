{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../generic
    ./hardware-configuration.nix
    ./persistence.nix
  ];

  hostConfig.desktop.enable = true;

  home-manager.users.lapine = {
    userConfig.desktop.enable = true;
  };

  networking = {
    hostName = "sampo";
    hostId = "0390c0e9";
    networkmanager.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    zfs.package = pkgs.zfs_unstable;
  };

  services.smartd.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
