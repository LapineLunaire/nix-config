{config, ...}: let
  securityHeaders = ''
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains"
      X-Content-Type-Options "nosniff"
      Referrer-Policy "strict-origin-when-cross-origin"
      -Server
    }
  '';
in {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # All certs use DNS-01 challenge via Cloudflare.
  # The --dns.resolvers flag points lego at Cloudflare's resolver (1.1.1.1) so it verifies DNS propagation against the same nameserver it just updated, avoiding stale cache issues.
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "certs@lunaire.eu";
      keyType = "ec384";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    certs."gf.lunaire.moe" = {};
    certs."auth.lunaire.moe" = {};
    certs."git.lunaire.moe" = {};
    certs."ha.lunaire.moe" = {};
    certs."pga.lunaire.moe" = {};
    certs."qbt.lunaire.moe" = {};
    certs."up.lunaire.moe" = {};
    certs."misc.lunaire.moe" = {};
    certs."kv.lunaire.moe" = {};
    certs."vw.lunaire.moe" = {};
  };

  users.users.caddy.extraGroups = ["acme"];

  services.caddy = {
    enable = true;
    virtualHosts."gf.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/gf.lunaire.moe/cert.pem /var/lib/acme/gf.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.19:3000
    '';
    # auth: LAN/VPN + forgejo (OIDC backchannel) + pgadmin (OIDC backchannel) + uptime-kuma (health check).
    virtualHosts."auth.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/auth.lunaire.moe/cert.pem /var/lib/acme/auth.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.12 10.28.34.20 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.11:9091
    '';
    # git: LAN/VPN + infra subnet (clones from other LAN hosts) + ci-runner + uptime-kuma.
    virtualHosts."git.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/git.lunaire.moe/cert.pem /var/lib/acme/git.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.32.0/23 10.28.34.13 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.12:3000
    '';
    virtualHosts."ha.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/ha.lunaire.moe/cert.pem /var/lib/acme/ha.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.14:8123
    '';
    virtualHosts."pga.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/pga.lunaire.moe/cert.pem /var/lib/acme/pga.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.20:5000
    '';
    virtualHosts."qbt.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/qbt.lunaire.moe/cert.pem /var/lib/acme/qbt.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.15:4000
    '';
    virtualHosts."up.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/up.lunaire.moe/cert.pem /var/lib/acme/up.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24
      respond @not_allowed 403
      reverse_proxy 10.28.34.18:3001
    '';
    virtualHosts."misc.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/misc.lunaire.moe/cert.pem /var/lib/acme/misc.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      root * /mnt/samba/misc
      file_server browse
    '';
    virtualHosts."kv.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/kv.lunaire.moe/cert.pem /var/lib/acme/kv.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.17:5000
    '';
    virtualHosts."vw.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/vw.lunaire.moe/cert.pem /var/lib/acme/vw.lunaire.moe/key.pem
      ${securityHeaders}
      @not_allowed not remote_ip 10.28.64.0/24 10.28.96.0/24 10.100.0.0/24 10.1.0.0/24 10.28.34.18
      respond @not_allowed 403
      reverse_proxy 10.28.34.16:8222 {
        header_up X-Real-IP {remote_host}
      }
    '';
    # Public file server, accessible only via sparxie over WireGuard.
    virtualHosts."http://10.73.212.2:9000".extraConfig = ''
      root * /mnt/samba/misc
      file_server browse
    '';
  };
}
