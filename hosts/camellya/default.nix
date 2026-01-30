{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/nixos/generic
    ../../modules/nixos/desktop
    ./hardware-configuration.nix
    ./persistence.nix
    ./audio.nix
    ./display.nix
  ];

  networking = {
    hostName = "camellya";
    hostId = "0d339030";
    networkmanager.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          X86_NATIVE_CPU = yes;
        };
      };
    });
    kernelParams = ["amd_pstate=active"];
    zfs.package = pkgs.zfs_unstable;
  };

  powerManagement.cpuFreqGovernor = "performance";

  services.udev.packages = with pkgs; [
    wooting-udev-rules
  ];

  system.stateVersion = "25.11";
}
