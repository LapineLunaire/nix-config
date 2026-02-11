{pkgs, ...}: {
  imports = [
    ../../modules/nixos/generic
    ./hardware-configuration.nix
    ./persistence.nix
    ./services
    ./sops.nix
  ];

  secureboot.enable = false;

  networking = {
    hostName = "sparxie";
    hostId = "33dd4911";
    networkmanager.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    zfs.package = pkgs.zfs_unstable;
  };

  system.stateVersion = "25.11";
}
