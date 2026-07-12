{lib, ...}: let
  securityHeaders = import ../../../modules/nixos/caddy-security-headers.nix;
  wg = import ../../../modules/nixos/sparkle-sparxie-wireguard.nix;
  # Source-IP base allowlist applied to every vhost: both LANs and both WireGuard subnets (see trusted-subnets.nix).
  baseAllow = (import ../../../modules/nixos/trusted-subnets.nix).subnets;
  net = import ../microvms/vm-net.nix;
  # uptimeKuma in extraAllow is uptime-kuma probing each service through the proxy.
  uptimeKuma = net.vmAddress.uptime-kuma;
  # Each entry becomes <name>.lunaire.moe behind the wildcard cert, and coredns.nix generates a zone CNAME per entry (bump the zone serial when this set changes). extraAllow lists callers beyond baseAllow; body is the service-specific Caddy config.
  vhosts = {
    gf = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.vmAddress.monitoring}:3000";
    };
    # auth: forgejo (OIDC backchannel) + pgadmin (OIDC backchannel) + uptime-kuma (health check).
    auth = {
      extraAllow = [net.vmAddress.forgejo net.vmAddress.pgadmin uptimeKuma];
      body = "reverse_proxy ${net.vmAddress.authelia}:9091";
    };
    # git: DMZ subnet (clones from other server hosts) + ci-runner + uptime-kuma.
    git = {
      extraAllow = [(import ../dmz-net.nix).subnet net.vmAddress.ci-runner uptimeKuma];
      body = "reverse_proxy ${net.vmAddress.forgejo}:3000";
    };
    ha = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.vmAddress.homeassistant}:8123";
    };
    pga = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.vmAddress.pgadmin}:5000";
    };
    qbt = {
      extraAllow = [uptimeKuma];
      body = "reverse_proxy ${net.vmAddress.qbittorrent}:4000";
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
      body = "reverse_proxy ${net.vmAddress.kavita}:5000";
    };
    vw = {
      extraAllow = [uptimeKuma];
      body = ''
        reverse_proxy ${net.vmAddress.vaultwarden}:8222 {
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
      "http://${wg.sparkle.ip}:9000".extraConfig = ''
        root * /mnt/samba/misc
        file_server browse
      '';
    };
}
