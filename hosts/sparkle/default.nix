{pkgs, ...}: {
  imports = [
    ../generic
    ./hardware-configuration.nix
    ./persistence.nix
  ];

  networking = {
    hostName = "sparkle";
    hostId = "d38a0d1c";
    networkmanager.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  system.stateVersion = "25.11";
}
