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

    trustedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "Additional TCP ports restricted like SSH to trusted subnets and connections.";
    };

    trustedSubnetsNft = lib.mkOption {
      type = lib.types.str;
      default = builtins.concatStringsSep ", " config.host.trustedSubnets;
      readOnly = true;
      description = "Trusted subnets formatted for nftables sets.";
    };

    alertEmail = lib.mkOption {
      type = lib.types.str;
      default = "carmilla@lunaire.eu";
      description = "Recipient of service alerts and failure mail.";
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
  };
}
