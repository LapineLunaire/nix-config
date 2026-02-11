{config, ...}: {
  networking.firewall.allowedTCPPorts = [80 443 8448];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "certs@lunaire.eu";
      keyType = "ec384";
    };
    certs."matrix.bunny.enterprises" = {
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
    virtualHosts."matrix.bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/matrix.bunny.enterprises/cert.pem /var/lib/acme/matrix.bunny.enterprises/key.pem
      reverse_proxy [::1]:6167
    '';
    virtualHosts."matrix.bunny.enterprises:8448".extraConfig = ''
      tls /var/lib/acme/matrix.bunny.enterprises/cert.pem /var/lib/acme/matrix.bunny.enterprises/key.pem
      reverse_proxy [::1]:6167
    '';
  };
}
