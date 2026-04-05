{config, ...}: {
  networking.firewall.allowedTCPPorts = [80 443];

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
    certs."auth.lunaire.moe" = {};
    certs."git.lunaire.moe" = {};
    certs."ha.lunaire.moe" = {};
    certs."pga.lunaire.moe" = {};
    certs."qbt.lunaire.moe" = {};
    certs."up.lunaire.moe" = {};
    certs."misc.lunaire.moe" = {};
    certs."vw.lunaire.moe" = {};
  };

  users.users.caddy.extraGroups = ["acme"];

  services.caddy = {
    enable = true;
    virtualHosts."auth.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/auth.lunaire.moe/cert.pem /var/lib/acme/auth.lunaire.moe/key.pem
      reverse_proxy localhost:2000
    '';
    virtualHosts."git.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/git.lunaire.moe/cert.pem /var/lib/acme/git.lunaire.moe/key.pem
      reverse_proxy localhost:3000
    '';
    virtualHosts."ha.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/ha.lunaire.moe/cert.pem /var/lib/acme/ha.lunaire.moe/key.pem
      reverse_proxy localhost:7000
    '';
    virtualHosts."pga.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/pga.lunaire.moe/cert.pem /var/lib/acme/pga.lunaire.moe/key.pem
      reverse_proxy localhost:5000
    '';
    # qBittorrent runs in the qbtvpn network namespace, so it is unreachable on localhost. Proxy to the namespace's veth address instead.
    virtualHosts."qbt.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/qbt.lunaire.moe/cert.pem /var/lib/acme/qbt.lunaire.moe/key.pem
      forward_auth localhost:2000 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
      }
      reverse_proxy ${config.vpnNamespaces.qbtvpn.namespaceAddress}:4000
    '';
    virtualHosts."up.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/up.lunaire.moe/cert.pem /var/lib/acme/up.lunaire.moe/key.pem
      reverse_proxy localhost:8000
    '';
    virtualHosts."misc.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/misc.lunaire.moe/cert.pem /var/lib/acme/misc.lunaire.moe/key.pem
      root * /mnt/samba/misc
      file_server browse
    '';
    virtualHosts."vw.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/vw.lunaire.moe/cert.pem /var/lib/acme/vw.lunaire.moe/key.pem
      reverse_proxy localhost:6000 {
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
