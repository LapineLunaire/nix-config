{
  lib,
  pkgs,
  ...
}: let
  wan = import ./wan-net.nix;
in {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/networking/ssh-ip-whitelist.nix
    ../../modules/nixos/services/zfs.nix
    ../../modules/nixos/services/mail-relay.nix
    ../../modules/nixos/services/borg-backup.nix
    ../../modules/nixos/networking/wireguard-tunnel.nix
    ../../modules/nixos/services/caddy.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
    ./auto-update.nix
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

  host.flakePath = "/persist/nix-config";
  host.smtp.passwordSecret = "smtp-password";
  host.acmeEmail = "certs@lunaire.eu";
  host.dnsApiTokenSecret = "bunny-enterprises-dns-api-token";

  host.wireguardTunnel = {
    prefixLength = "31";
    listenPort = wan.wireguardPort;
    local.ip = "10.73.212.1";
    peer = {
      ip = "10.73.212.0";
      publicKey = "fU36EC/ymy4d1XwJCfqAXKEX8dRK/WuMFBbh6OtKBRM=";
    };
  };

  nixpkgs.config.allowUnfree = true;

  services.borgbackup.jobs.hetzner.startAt = "03:00";
  services.fwupd.enable = lib.mkForce false;

  # Hetzner's IPv4 gateway is outside the /32, so it needs GatewayOnLink.
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig.DHCP = "no";
    address = [
      "${wan.ipv4}/32"
      "${wan.ipv6}/64"
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

  system.stateVersion = "26.05";
  home-manager.users.carmilla.home.stateVersion = "26.05";
}
