{
  config,
  pkgs,
  ...
}: let
  public = import ./wan-net.nix;
in {
  imports = [
    ../../modules/site.nix
    ../../modules/nixos/generic
    ../../modules/nixos/auto-update.nix
    ../../modules/nixos/ip-whitelist.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./services
  ];

  networking = {
    hostName = "sparxie";
    hostId = "33dd4911";
  };

  # The WireGuard tunnel to sparkle: a /31 point-to-point pair. sparxie listens on its static VPS address and sparkle dials in; the private key secret lives in this host's sops.
  site.wireguardTunnel = {
    prefixLength = "31";
    listenPort = 47329;
    local.ip = "10.73.212.1";
    peer = {
      ip = "10.73.212.0";
      publicKey = "fU36EC/ymy4d1XwJCfqAXKEX8dRK/WuMFBbh6OtKBRM=";
    };
  };

  # SSH only accepts connections from the external addresses in these secrets, nothing else is exempt. A stale whitelist is recovered through the Hetzner console.
  ip-whitelist.ssh = {
    ports = [22];
    ipv4File = config.sops.secrets."ssh-allowed-ips-v4".path;
    ipv6File = config.sops.secrets."ssh-allowed-ips-v6".path;
  };

  # Static network config per Hetzner VPS requirements (https://docs.hetzner.com/cloud/servers/static-configuration/).
  # The IPv4 gateway (172.31.1.1) is off-subnet relative to the /32 address, so GatewayOnLink is required.
  # The IPv6 default gateway is the router's link-local address.
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig.DHCP = "no";
    address = [
      "${public.ipv4}/32"
      "${public.ipv6}/64"
    ];
    routes = [
      {
        Gateway = "172.31.1.1";
        GatewayOnLink = true;
      }
      {Gateway = "fe80::1";}
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
    # Explicit zfs major version pin, upgraded deliberately in lockstep with the kernel pin above.
    zfs.package = pkgs.zfs_2_4;
  };

  system.stateVersion = "26.05";
}
