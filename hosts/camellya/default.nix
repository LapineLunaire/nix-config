{
  pkgs,
  lib,
  ...
}: {
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

  system.stateVersion = "25.11";
}
