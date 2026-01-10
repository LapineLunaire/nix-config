{pkgs, ...}: {
  imports = [
    ../generic
    ../generic/users/lapine.nix
    ./hardware-configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    # zfs_unstable for newer kernel compatibility
    zfs.package = pkgs.zfs_unstable;
  };

  networking = {
    hostName = "sampo";
    # hostId is required for ZFS
    hostId = "0390c0e9";
    networkmanager.enable = true;
  };

  system.stateVersion = "25.11";
}
