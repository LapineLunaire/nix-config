{
  pkgs,
  lib,
  config,
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
    kernelPackages = pkgs.linuxPackages_latest.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          X86_NATIVE_CPU = yes;
        };
      };
    });
    zfs.package = pkgs.zfs_unstable;
  };

  system.stateVersion = "25.11";
}
