{pkgs, ...}: {
  imports = [
    ../generic
    ../desktop
    ./hardware-configuration.nix
    ./persistence.nix
    ./display.nix
    ./services.nix
  ];

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

  powerManagement.cpuFreqGovernor = "performance";

  system.stateVersion = "25.11";
}
