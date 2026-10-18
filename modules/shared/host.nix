{
  config,
  lib,
  ...
}: {
  options.host = {
    flakePath = lib.mkOption {
      type = lib.types.str;
      description = "Path to this host's flake checkout.";
    };

    trustedSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Client subnets trusted to reach this host's admin services.";
    };

    trustedSubnetsNft = lib.mkOption {
      type = lib.types.str;
      default = builtins.concatStringsSep ", " config.host.trustedSubnets;
      readOnly = true;
      description = "Trusted subnets formatted for nftables sets.";
    };

    smtp = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "smtp.protonmail.ch";
        description = "SMTP server for outgoing service mail.";
      };

      port = lib.mkOption {
        type = lib.types.str;
        default = "587";
        description = "SMTP submission port.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "noreply@lunaire.eu";
        description = "SMTP account and sender address.";
      };

      passwordSecret = lib.mkOption {
        type = lib.types.str;
        description = "SOPS secret containing the SMTP password.";
      };
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "Account email for ACME certificate registration.";
    };

    dnsApiTokenSecret = lib.mkOption {
      type = lib.types.str;
      description = "SOPS secret containing the zone-scoped Cloudflare DNS API token.";
    };

    autoUpdate = {
      owner = lib.mkOption {
        type = lib.types.str;
        description = "Checkout owner used for Git operations.";
      };

      branch = lib.mkOption {
        type = lib.types.str;
        description = "Origin branch verified before each upgrade.";
      };

      allowedSigners = lib.mkOption {
        type = lib.types.lines;
        description = "SSH allowed-signers entries trusted to sign upgrades.";
      };
    };

    wireguardTunnel = {
      prefixLength = lib.mkOption {
        type = lib.types.str;
        description = "Prefix length for the tunnel addresses.";
      };

      listenPort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "UDP listening port, or null for an outgoing connection.";
      };

      local.ip = lib.mkOption {
        type = lib.types.str;
        description = "This system's tunnel address.";
      };

      peer = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "The peer's tunnel address.";
        };

        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "The peer's WireGuard public key.";
        };

        endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Peer host and port, or null to wait for the peer to connect.";
        };
      };
    };
  };
}
