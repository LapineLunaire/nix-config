{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../../shared/host.nix];

  options.caddy.securityHeaders = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = ''
      header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
      }
    '';
    description = "Security headers shared by Caddy virtual hosts.";
  };

  options.caddy.tlsDns = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
    '';
    description = "Cloudflare DNS challenge settings shared by Caddy virtual hosts.";
  };

  config = let
    tokenSecret = config.host.dnsApiTokenSecret;
  in {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    networking.firewall.allowedUDPPorts = [443];

    services.caddy.enable = true;

    services.caddy.package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
      hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
    };

    sops.secrets.${tokenSecret} = {};
    sops.templates."caddy-dns-api-token.env" = {
      restartUnits = ["caddy.service"];
      content = ''
        CF_API_TOKEN=${config.sops.placeholder.${tokenSecret}}
      '';
      owner = "caddy";
    };
    services.caddy.environmentFile = config.sops.templates."caddy-dns-api-token.env".path;

    services.caddy.email = config.host.acmeEmail;
    services.caddy.globalConfig = ''
      key_type p384
      cert_issuer acme {
        dir https://acme-v02.api.letsencrypt.org/directory
        profile shortlived
      }
    '';
  };
}
