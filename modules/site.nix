# Declares the site option namespace: deployment parameters (trusted networks, mail relay) that each system defines for itself and modules read as config.site.*.
{
  config,
  lib,
  ...
}: {
  options.site = {
    trustedSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Client subnets trusted to reach this system's admin surfaces.";
    };

    trustedSubnetsNft = lib.mkOption {
      type = lib.types.str;
      default = builtins.concatStringsSep ", " config.site.trustedSubnets;
      readOnly = true;
      description = "The trusted subnets comma-joined for nftables set literals.";
    };

    smtp = {
      host = lib.mkOption {
        type = lib.types.str;
        description = "SMTP submission host for outgoing service mail.";
      };

      port = lib.mkOption {
        type = lib.types.str;
        description = "SMTP submission port, a string for config-file interpolation.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        description = "SMTP account name, also used as the sender address.";
      };
    };

    wireguardTunnel = {
      prefixLength = lib.mkOption {
        type = lib.types.str;
        description = "Prefix length of the tunnel's point-to-point subnet, a string for address interpolation.";
      };

      listenPort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "UDP port this system listens on for the tunnel, null when this end only dials out.";
      };

      local.ip = lib.mkOption {
        type = lib.types.str;
        description = "This system's address inside the tunnel.";
      };

      peer = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "The peer's address inside the tunnel.";
        };

        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "The peer's WireGuard public key.";
        };

        endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "host:port this system dials the peer at, null when the peer dials in.";
        };
      };
    };
  };
}
