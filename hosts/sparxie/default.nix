{
  pkgs,
  sparxieWan,
  tunnelWeb,
  ...
}: {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/networking/ssh-ip-whitelist.nix
    ../../modules/nixos/services/zfs.nix
    ../../modules/nixos/services/mail-relay.nix
    ../../modules/nixos/services/borg-backup.nix
    ../../modules/nixos/networking/wireguard-tunnel.nix
    ../../modules/nixos/services/caddy.nix
    ../../modules/nixos/system/tmpfs-root.nix
    ./hardware-configuration.nix
    ../../modules/nixos/system/persistence.nix
    ../../modules/nixos/nix/auto-update.nix
    ./services/database.nix
    ./services/certificates.nix
    ./services/ejabberd.nix
    ./services/tuwunel.nix
    ./services/proxy.nix
  ];

  networking = {
    hostName = "sparxie";
    hostId = "33dd4911";
  };

  sops.defaultSopsFile = ./secrets.yaml;

  host.dnsApiTokenSecret = "bunny-enterprises-dns-api-token";

  host.wireguardTunnel = {
    inherit (tunnelWeb) prefixLength;
    listenPort = sparxieWan.wireguardPort;
    local.ip = tunnelWeb.sparxieAddress;
    peer = {
      ip = tunnelWeb.proxyAddress;
      publicKey = "fU36EC/ymy4d1XwJCfqAXKEX8dRK/WuMFBbh6OtKBRM=";
    };
  };

  services.fwupd.enable = false;

  # Hetzner's IPv4 gateway is outside the /32, so it needs GatewayOnLink.
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig.DHCP = "no";
    address = [
      "${sparxieWan.ipv4}/32"
      "${sparxieWan.ipv6}/64"
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
    # Update ZFS and the kernel together.
    zfs.package = pkgs.zfs_2_4;
  };

  system.stateVersion = "26.11";
  home-manager.users.carmilla.home.stateVersion = "26.11";
}
