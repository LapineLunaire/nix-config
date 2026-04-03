{pkgs, ...}: {
  imports = [
    ../../modules/nixos/generic
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./services
  ];

  networking = {
    hostName = "sparxie";
    hostId = "33dd4911";
    useDHCP = false;
  };

  # Static network config per Hetzner VPS requirements (https://docs.hetzner.com/cloud/servers/static-configuration/).
  # The IPv4 gateway (172.31.1.1) is off-subnet relative to the /32 address, so GatewayOnLink is required.
  # The IPv6 default gateway is the router's link-local address.
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
    kernelPackages = pkgs.linuxPackages_6_19;
    zfs.package = pkgs.zfs_2_4;
  };

  system.stateVersion = "26.05";
}
