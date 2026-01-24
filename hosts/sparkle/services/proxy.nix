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
      environmentFile = "/persist/secrets/cloudflare.env";
      group = "caddy";
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    certs."qbt.lunaire.moe" = {
      dnsProvider = "cloudflare";
      environmentFile = "/persist/secrets/cloudflare.env";
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
  };
}
