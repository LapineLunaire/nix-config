{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nixos/generic
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./services
  ];

  secureboot.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  networking = {
    hostName = "sparkle";
    hostId = "d38a0d1c";
    networkmanager = {
      enable = true;
      # Keep the IPMI interface unmanaged so NetworkManager doesn't touch its static config.
      unmanaged = ["ipmi0"];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_19.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          # WARNING: X86_NATIVE_CPU detects the build machine's CPU at compile time.
          # This host must be built on sparkle itself (or a machine with an identical CPU).
          # Building on a different microarchitecture will produce a mismatched kernel.
          X86_NATIVE_CPU = yes;
        };
      };
    });
    kernelParams = ["intel_pstate=active"];
    zfs.package = pkgs.zfs_2_4;
  };

  # With intel_pstate active, powersave lets HWP firmware handle frequency scaling.
  powerManagement.cpuFreqGovernor = "powersave";

  system.stateVersion = "26.05";
}
