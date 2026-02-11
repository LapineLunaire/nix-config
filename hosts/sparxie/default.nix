{pkgs, ...}: {
  imports = [
    ../../modules/nixos/generic
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./services
    ./sops.nix
  ];

  secureboot.enable = false;

  networking = {
    hostName = "sparxie";
    hostId = "33dd4911";
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks."30-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "no";
      address = [
        "46.225.108.230/32"
        "2a01:4f8:1c19:a249::1/64"
      ];
      routes = [
        {
          Gateway = "172.31.1.1";
          GatewayOnLink = true;
        }
        {Gateway = "fe80::1";}
      ];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    zfs.package = pkgs.zfs_unstable;
  };

  system.stateVersion = "25.11";
}
