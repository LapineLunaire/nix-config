{
  config,
  dmz,
  net,
  web,
  consoleKey,
  lib,
  ...
}: let
  inherit (net) nodeExporterPort;
  proxyAddress = net.vmAddress.proxy;
  monitoringAddress = net.vmAddress.monitoring;
  proxiedPorts = lib.optional (web.endpoints ? ${config.networking.hostName}) web.endpoints.${config.networking.hostName}.port;
in {
  imports = [
    ../../shared/host.nix
    ../../shared/nix-settings.nix
    ../system/security.nix
    ../system/zram.nix
    ../system/tmpfs-root.nix
    ../networking/firewall.nix
    ../services/openssh.nix
    ../programs/ghostty-terminfo.nix
    ./host-clock.nix
  ];

  options.microvmGuest.egress = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        proto = lib.mkOption {
          type = lib.types.enum ["tcp" "udp" "icmp"];
          description = "Protocol this flow uses. icmp takes no ports.";
        };
        ports = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = "Destination ports; empty allows any port of this protocol.";
        };

        sourcePorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = "Source ports; empty allows any source port.";
        };
        destinations = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Destination addresses or prefixes. Empty excludes private networks; explicit destinations may include them.";
        };
      };
    });
    default = [];
    description = "Outbound flows allowed across the host bridge. Empty denies off-segment egress.";
  };

  config = {
    assertions = [
      {
        assertion = config.microvm.devices == [] || !config.microvm.balloon;
        message = "Guests with passthrough devices must disable microvm.balloon.";
      }
    ];
    host.tmpfs = {
      rootSize = "50%";
      tmpSize = "25%";
    };
    fileSystems = {
      "/" = {
        # Keep the root device name that microvm.nix uses instead of "none".
        device = lib.mkForce "rootfs";
        neededForBoot = true;
      };
      "/persist" = {
        neededForBoot = true;
        options = ["nosuid" "nodev"];
      };
    };
    environment.persistence."/persist" = {
      directories = [
        "/var/lib"
        "/var/log"
        # Keeps the shell history of microvm -s sessions. Impermanence would create the persistent directory world-readable.
        {
          directory = "/root";
          mode = "0700";
        }
      ];
      files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    microvm = {
      hypervisor = "cloud-hypervisor";
      vcpu = lib.mkDefault 4;
      mem = lib.mkDefault 2048;
      shares = [
        {
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          proto = "virtiofs";
          readOnly = true;
        }
      ];
      writableStoreOverlay = "/nix/.rw-store";
      balloon = lib.mkDefault true;
      deflateOnOOM = true;
    };

    # The guest overlay cannot hardlink into the read-only host store.
    nix.settings.auto-optimise-store = lib.mkForce false;

    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    services.prometheus.exporters.node = {
      enable = true;
      port = nodeExporterPort;
    };

    services.openssh = {
      openFirewall = false;
      # Sparkle's console key logs in as root.
      settings.PermitRootLogin = lib.mkForce "prohibit-password";
    };
    microvm.vsock.ssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [consoleKey];

    networking.firewall.extraInputRules = lib.mkMerge [
      (lib.mkBefore ''
        ip saddr ${monitoringAddress} tcp dport ${toString nodeExporterPort} accept
      '')
      (lib.concatMapStrings (port: "ip saddr ${proxyAddress} tcp dport ${toString port} accept\n") proxiedPorts)
    ];
    networking.useDHCP = false;
    # Guest networking requires eth0.
    networking.usePredictableInterfaceNames = false;
    networking.nameservers = [net.vmAddress.dns];
    networking.defaultGateway = {
      address = dmz.gateway;
      interface = "eth0";
    };

    time.timeZone = "UTC";
    system.stateVersion = "26.05";
  };
}
