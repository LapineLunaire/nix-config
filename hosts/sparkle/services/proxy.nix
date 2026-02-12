{config, ...}: {
  networking.firewall.allowedTCPPorts = [80 443];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "certs@lunaire.eu";
      keyType = "ec384";
    };
    certs."git.lunaire.moe" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      group = "caddy";
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    certs."qbt.lunaire.moe" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      group = "caddy";
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    certs."pga.lunaire.moe" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      group = "caddy";
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    certs."ha.lunaire.moe" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      group = "caddy";
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    certs."vw.lunaire.moe" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      group = "caddy";
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."git.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/git.lunaire.moe/cert.pem /var/lib/acme/git.lunaire.moe/key.pem
      reverse_proxy localhost:3000
    '';
    virtualHosts."qbt.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/qbt.lunaire.moe/cert.pem /var/lib/acme/qbt.lunaire.moe/key.pem
      reverse_proxy ${config.vpnNamespaces.qbtvpn.namespaceAddress}:4000
    '';
    virtualHosts."ha.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/ha.lunaire.moe/cert.pem /var/lib/acme/ha.lunaire.moe/key.pem
      reverse_proxy localhost:7000
    '';
    virtualHosts."pga.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/pga.lunaire.moe/cert.pem /var/lib/acme/pga.lunaire.moe/key.pem
      reverse_proxy localhost:5000
    '';
    virtualHosts."vw.lunaire.moe".extraConfig = ''
      tls /var/lib/acme/vw.lunaire.moe/cert.pem /var/lib/acme/vw.lunaire.moe/key.pem
      reverse_proxy localhost:6000 {
        header_up X-Real-IP {remote_host}
      }
    '';
  };
}
