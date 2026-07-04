{
  config,
  lib,
  ...
}: let
  securityHeaders = ''
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains"
      X-Content-Type-Options "nosniff"
      Referrer-Policy "strict-origin-when-cross-origin"
      -Server
    }
  '';
  # Source-IP base allowlist applied to every vhost: LAN, guest, WireGuard, and site-to-site subnets.
  baseAllow = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];
  # Each entry becomes <name>.lunaire.moe behind the wildcard cert. extraAllow lists callers beyond baseAllow; body is the service-specific Caddy config.
  vhosts = {
    gf = {
      extraAllow = ["10.28.34.18"];
      body = "reverse_proxy 10.28.34.19:3000";
    };
    # auth: forgejo (OIDC backchannel) + pgadmin (OIDC backchannel) + uptime-kuma (health check).
    auth = {
      extraAllow = ["10.28.34.12" "10.28.34.20" "10.28.34.18"];
      body = "reverse_proxy 10.28.34.11:9091";
    };
    # git: infra subnet (clones from other LAN hosts) + ci-runner + uptime-kuma.
    git = {
      extraAllow = ["10.28.32.0/23" "10.28.34.13" "10.28.34.18"];
      body = "reverse_proxy 10.28.34.12:3000";
    };
    ha = {
      extraAllow = ["10.28.34.18"];
      body = "reverse_proxy 10.28.34.14:8123";
    };
    pga = {
      extraAllow = ["10.28.34.18"];
      body = "reverse_proxy 10.28.34.20:5000";
    };
    qbt = {
      extraAllow = ["10.28.34.18"];
      body = "reverse_proxy 10.28.34.15:4000";
    };
    up = {
      extraAllow = [];
      body = "reverse_proxy 10.28.34.18:3001";
    };
    misc = {
      extraAllow = ["10.28.34.18"];
      body = ''
        root * /mnt/samba/misc
        file_server browse
      '';
    };
    kv = {
      extraAllow = ["10.28.34.18"];
      body = "reverse_proxy 10.28.34.17:5000";
    };
    vw = {
      extraAllow = ["10.28.34.18"];
      body = ''
        reverse_proxy 10.28.34.16:8222 {
          header_up X-Real-IP {remote_host}
        }
      '';
    };
  };
  mkVhost = name: v: {
    name = "${name}.lunaire.moe";
    value.extraConfig = ''
      tls /var/lib/acme/lunaire.moe/cert.pem /var/lib/acme/lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip ${lib.concatStringsSep " " (baseAllow ++ v.extraAllow)}
      respond @not_allowed 403
      ${v.body}
    '';
  };
in {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # All certs use DNS-01 challenge via Cloudflare.
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "certs@lunaire.eu";
      keyType = "ec384";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      # Port-53 DNS from this host resolves through the local split-horizon CoreDNS, which never holds the public _acme-challenge record, so lego's propagation check can never pass. Wait a fixed time for Cloudflare to publish the record before the ACME server validates.
      extraLegoFlags = ["--dns.propagation-wait" "60s"];
      # Caddy reads cert files off disk rather than managing ACME itself, so reload it after each renewal to pick up the new cert.
      reloadServices = ["caddy.service"];
    };
    # One wildcard cert for all proxied services, so CT logs only expose the apex instead of the per-service hostnames.
    certs."lunaire.moe" = {extraDomainNames = ["*.lunaire.moe"];};
    # unifi-core (served directly, no proxy) only accepts an RSA cert via its unifi-core.crt/.key files.
    certs."unifi.lunaire.moe" = {keyType = "rsa4096";};
  };

  users.users.caddy.extraGroups = ["acme"];

  services.caddy = {
    enable = true;
    virtualHosts =
      lib.mapAttrs' mkVhost vhosts
      // {
        # Public file server, accessible only via sparxie over WireGuard.
        "http://10.73.212.2:9000".extraConfig = ''
          root * /mnt/samba/misc
          file_server browse
        '';
      };
  };
}
