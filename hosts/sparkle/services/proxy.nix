{lib, ...}: let
  securityHeaders = import ../../../modules/nixos/caddy-security-headers.nix;
  # Source-IP base allowlist applied to every vhost: both LANs and both WireGuard subnets (see trusted-subnets.nix).
  baseAllow = import ../trusted-subnets.nix;
  net = import ../microvms/vm-net.nix;
  # uptimeKuma in extraAllow is uptime-kuma probing each service through the proxy.
  uptimeKuma = net.ip."uptime-kuma";
  # Each entry becomes <name>.lunaire.moe behind the wildcard cert, and coredns.nix generates a zone CNAME per entry (bump the zone serial when this set changes). extraAllow lists callers beyond baseAllow; body is the service-specific Caddy config.
  vhosts = {
    gf = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.ip.monitoring}:3000";
    };
    # auth: forgejo (OIDC backchannel) + pgadmin (OIDC backchannel) + uptime-kuma (health check).
    auth = {
      extraAllow = [net.ip.forgejo net.ip.pgadmin uptimeKuma];
      body = "reverse_proxy ${net.ip.authelia}:9091";
    };
    # git: infra subnet (clones from other LAN hosts) + ci-runner + uptime-kuma.
    git = {
      extraAllow = ["10.28.32.0/23" net.ip.ci-runner uptimeKuma];
      body = "reverse_proxy ${net.ip.forgejo}:3000";
    };
    ha = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.ip.homeassistant}:8123";
    };
    pga = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.ip.pgadmin}:5000";
    };
    qbt = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.ip.qbittorrent}:4000";
    };
    up = {
      extraAllow = [];
      body = "reverse_proxy ${uptimeKuma}:3001";
    };
    misc = {
      extraAllow = [uptimeKuma];
      body = ''
        root * /mnt/samba/misc
        file_server browse
      '';
    };
    kv = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.ip.kavita}:5000";
    };
    vw = {
      extraAllow = [uptimeKuma];
      body = ''
        reverse_proxy ${net.ip.vaultwarden}:8222 {
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
  security.acme = {
    # One wildcard cert for all proxied services, so CT logs only expose the apex instead of the per-service hostnames.
    certs."lunaire.moe" = {extraDomainNames = ["*.lunaire.moe"];};
    # unifi-core (served directly, no proxy) only accepts an RSA cert via its unifi-core.crt/.key files.
    certs."unifi.lunaire.moe" = {keyType = "rsa4096";};
  };

  services.caddy.virtualHosts =
    lib.mapAttrs' mkVhost vhosts
    // {
      # Public file server, accessible only via sparxie over WireGuard.
      "http://10.73.212.2:9000".extraConfig = ''
        root * /mnt/samba/misc
        file_server browse
      '';
    };
}
