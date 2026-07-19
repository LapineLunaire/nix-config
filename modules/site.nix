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
  };
}
