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
    ./services
    ./sops.nix
  ];

  secureboot.enable = true;

  networking = {
    hostName = "sparkle";
    hostId = "d38a0d1c";
    networkmanager = {
      enable = true;
      unmanaged = ["ipmi0"];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_19.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          X86_NATIVE_CPU = yes;
        };
      };
    });
    zfs.package = pkgs.zfs_2_4;
  };

  system.stateVersion = "26.05";
}
