{
  config,
  lib,
  pkgs,
  ...
}: let
  net = import ./vm-net.nix;
  # sparkle's SSH host public key, authorized for root below for the microvm -s VSOCK console.
  hostConsoleKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJ+Zb08V2BIx3TnFgha04A55Vo9d0ftNpNvnRgfO3Gk";
in {
  imports = [
    ../../../modules/nix-settings.nix
    ../../../modules/nixos/security.nix
  ];

  # TCP ports the host may reach on this VM; each becomes an input-chain accept from the bridge address (Caddy and other host services).
  options.microvmGuest.hostIngressTCPPorts = lib.mkOption {
    type = lib.types.listOf lib.types.port;
    default = [];
  };

  config = {
    environment.systemPackages = [pkgs.ghostty.terminfo];
    # /var/lib and /var/log bind-mounted from /persist (virtiofs share at /persist).
    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist" = {
      directories = [
        "/var/lib"
        "/var/log"
      ];
      files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };

    microvm = {
      hypervisor = "cloud-hypervisor";
      vcpu = lib.mkDefault 4;
      mem = lib.mkDefault 2048;
      # Shared host nix store (read-only). Do NOT set fileSystems."/nix/store" manually; microvm.nix manages the overlay when writableStoreOverlay is set.
      shares = [
        {
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          proto = "virtiofs";
        }
      ];
      writableStoreOverlay = "/nix/.rw-store";
      # balloon is bool; initialBalloonMem (MB) sets starting size per VM.
      balloon = lib.mkDefault true;
      deflateOnOOM = true;
    };

    # sops-nix derives age key from the persisted SSH host key.
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    # node_exporter on every VM, scraped by the monitoring VM only.
    services.prometheus.exporters.node.enable = true;

    # sshd serves the root VSOCK console (microvm -s) and, on git-ssh VMs, the service's git user.
    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        # Key-only root login.
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
    # Serve sshd on VSOCK for the microvm -s console.
    microvm.vsock.ssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [hostConsoleKey];

    networking.firewall.extraInputRules = lib.mkMerge [
      (lib.mkBefore ''
        ip saddr ${net.vmAddress.monitoring} tcp dport 9100 accept
      '')
      (lib.concatMapStrings (port: "ip saddr ${net.hostAddress} tcp dport ${toString port} accept\n") config.microvmGuest.hostIngressTCPPorts)
    ];
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    networking.useDHCP = false;
    # Force eth0 naming; all VM configs reference eth0.
    networking.usePredictableInterfaceNames = false;
    networking.nameservers = [net.hostAddress];
    networking.defaultGateway = {
      address = net.hostAddress;
      interface = "eth0";
    };

    time.timeZone = "UTC";
    system.stateVersion = "26.05";
  };
}
