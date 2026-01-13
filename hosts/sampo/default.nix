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

  myConfig.desktop.enable = true;
  myConfig.gaming.enable = true;

  networking = {
    hostName = "sampo";
    # hostId is required for ZFS
    hostId = "0390c0e9";
    networkmanager.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    # zfs_unstable for newer kernel compatibility
    zfs.package = pkgs.zfs_unstable;
  };

  # Disable smartd (VM has no physical disks)
  services.smartd.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
