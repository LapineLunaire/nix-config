{
  config,
  lib,
  pkgs,
  ...
}: let
  smtp = config.site.smtp;
  dmz = import ./dmz-net.nix;
in {
  imports = [
    ../../modules/site.nix
    ../../modules/nixos/generic
    ../../modules/nixos/packages.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./services
    ./microvms
    ./auto-update.nix
  ];

  secureboot.enable = true;

  # Client subnets trusted to reach sparkle's admin surfaces (sshd, Caddy vhosts, VM ICMP, Samba, iperf3): LAN (10.28.64.0/24), WireGuard VPN (10.28.96.0/24), Nox's LAN (10.100.0.0/24), Nox's WireGuard (10.1.0.0/24).
  site.trustedSubnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];

  # The ProtonMail SMTP submission endpoint and the noreply relay account, used by msmtp for smartd alerts. The password secret lives in this host's sops.
  site.smtp = {
    host = "smtp.protonmail.ch";
    port = "587";
    user = "noreply@lunaire.eu";
  };

  # ACME account email for the Cloudflare DNS-01 certs (see modules/nixos/caddy.nix).
  site.acmeEmail = "certs@lunaire.eu";

  # The WireGuard tunnel to sparxie: a /31 point-to-point pair. sparkle dials out to sparxie's static VPS address; the private key secret lives in this host's sops.
  site.wireguardTunnel = {
    prefixLength = "31";
    local.ip = "10.73.212.0";
    peer = {
      ip = "10.73.212.1";
      publicKey = "VjVuhnnTEHuGssQOp0iM1yU0BLT34VWm3k00e8tDkSg=";
      endpoint = "46.225.108.230:47329";
    };
  };

  networking = {
    hostName = "sparkle";
    hostId = "d38a0d1c";
    # systemd-resolved intercepts DNS and breaks CoreDNS. Disable it and point resolv.conf directly at the local CoreDNS instance instead.
    nameservers = [dmz.hostAddress];
  };

  services.resolved.enable = false;

  # sshd only accepts connections from the trusted client subnets, keeping it unreachable from the VM bridge, the DMZ, the management network, and the sparxie tunnel.
  services.openssh.openFirewall = false;
  networking.firewall.extraInputRules = ''
    ip saddr { ${config.site.trustedSubnetsNft} } tcp dport 22 accept
  '';

  # Interface names (sfp0, sfp1, ipmi0) are assigned by sops-rendered .link files in /etc/systemd/network/ based on MAC addresses. sfp0 is the primary uplink with a static IP; sfp1 and ipmi0 are left unmanaged.
  systemd.network.networks = {
    "10-sfp0" = {
      matchConfig.Name = "sfp0";
      networkConfig = {
        DHCP = "no";
        Address = "${dmz.hostAddress}/${dmz.prefixLength}";
        Gateway = dmz.gateway;
      };
    };
    "10-sfp1" = {
      matchConfig.Name = "sfp1";
      linkConfig.Unmanaged = true;
    };
    "99-ipmi0" = {
      matchConfig.Name = "ipmi0";
      # Leave the IPMI interface alone; static config lives on the BMC.
      linkConfig.Unmanaged = true;
    };
  };

  # System SMTP relay so automated daemons (smartd) can send alerts via ProtonMail.
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    accounts.default = {
      inherit (smtp) host port user;
      auth = true;
      tls = true;
      from = smtp.user;
      passwordeval = "cat ${config.sops.secrets."smtp-password".path}";
    };
  };

  # Prevent host from claiming the Zigbee stick; its USB controller is passed through to the HA VM.
  boot.blacklistedKernelModules = ["cp210x"];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18.extend (
      self: super: {
        kernel = super.kernel.override {
          structuredExtraConfig = with lib.kernel; {
            # WARNING: X86_NATIVE_CPU detects the build machine's CPU at compile time.
            # This host must be built on sparkle itself (or a machine with an identical CPU).
            # Building on a different microarchitecture will produce a mismatched kernel.
            X86_NATIVE_CPU = yes;
          };
        };
      }
    );
    kernelParams = [
      "intel_pstate=active"
      "intel_iommu=on"
      "iommu=pt"
    ];
    # Explicit zfs major version pin, upgraded deliberately in lockstep with the kernel pin above.
    zfs.package = pkgs.zfs_2_4;
  };

  # With intel_pstate active, powersave lets HWP firmware handle frequency scaling.
  powerManagement.cpuFreqGovernor = "powersave";

  system.stateVersion = "26.05";
}
