# Caddy with ACME via Cloudflare DNS-01. Hosts define their certs and vhosts; the cloudflare-dns-api-token secret comes from each host's sops file.
{config, ...}: {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  sops.secrets."cloudflare-dns-api-token" = {};
  sops.templates."cloudflare-dns-api-token.env" = {
    content = ''
      CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-dns-api-token"}
    '';
    owner = "acme";
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = config.site.acmeEmail;
      keyType = "ec384";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      # Wait a fixed time for Cloudflare to publish the _acme-challenge record instead of lego's resolver-based propagation check, which breaks on hosts whose resolver is a split-horizon DNS that never holds the public record.
      extraLegoFlags = ["--dns.propagation-wait" "60s"];
      # Caddy reads cert files off disk rather than managing ACME itself, so reload it after each renewal to pick up the new cert.
      reloadServices = ["caddy.service"];
    };
  };

  users.users.caddy.extraGroups = ["acme"];

  services.caddy.enable = true;
}
