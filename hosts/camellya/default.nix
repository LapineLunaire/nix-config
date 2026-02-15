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
    ./tmpfiles.nix
    ./sops.nix
    ./services
    ./display.nix
  ];

  secureboot.enable = true;

  networking = {
    hostName = "camellya";
    hostId = "0d339030";
    networkmanager.enable = true;
  };

  boot = {
    # TODO: switch back to linuxPackages_latest when ZFS supports 6.19
    kernelPackages = pkgs.linuxPackages_6_18.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          X86_NATIVE_CPU = yes;
        };
      };
    });
    kernelParams = ["amd_pstate=active"];
    zfs.package = pkgs.zfs_unstable;
  };

  powerManagement.cpuFreqGovernor = "powersave";

  services.udev.packages = with pkgs; [
    wooting-udev-rules
  ];

  system.stateVersion = "26.05";
}
