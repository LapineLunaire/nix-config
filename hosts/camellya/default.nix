{
  lib,
  pkgs,
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
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          # WARNING: X86_NATIVE_CPU detects the build machine's CPU at compile time.
          # This host must be built on camellya itself (or a machine with an identical CPU).
          # Building on a different microarchitecture will produce a mismatched kernel.
          X86_NATIVE_CPU = yes;
        };
      };
    });
    # With amd_pstate active, powersave lets the firmware (CPPC) handle frequency scaling.
    kernelParams = ["amd_pstate=active"];
    zfs.package = pkgs.zfs_2_4;
  };

  powerManagement.cpuFreqGovernor = "powersave";

  services.udev.packages = with pkgs; [
    wooting-udev-rules
  ];

  system.stateVersion = "26.05";
}
