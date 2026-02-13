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
    # TODO: switch back to linuxPackages_latest when ZFS supports 6.19
    kernelPackages = pkgs.linuxPackages_6_18.extend (self: super: {
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
