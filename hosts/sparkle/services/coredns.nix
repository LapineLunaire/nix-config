{...}: {
  networking.firewall = {
    allowedUDPPorts = [53];
    allowedTCPPorts = [53];
  };

  environment.etc."coredns/zones/db.lunaire.moe".text = ''
    $ORIGIN lunaire.moe.
    $TTL 3600

    @       IN SOA  sparkle.lunaire.moe. hostmaster.lunaire.moe. (
                    2026040401 ; serial — format YYYYMMDDnn, bump on every zone change
                    3600       ; refresh
                    900        ; retry
                    604800     ; expire
                    86400      ; minimum
            )

    @       IN NS   sparkle.lunaire.moe.

    sparkle  IN A    10.28.32.25
    camellya IN A    10.28.64.96
    git      IN CNAME sparkle.lunaire.moe.
    ha       IN CNAME sparkle.lunaire.moe.
    misc     IN CNAME sparkle.lunaire.moe.
    pga      IN CNAME sparkle.lunaire.moe.
    qbt      IN CNAME sparkle.lunaire.moe.
    up       IN CNAME sparkle.lunaire.moe.
    vw       IN CNAME sparkle.lunaire.moe.
  '';

  # Reverse DNS zone for 10.28.0.0/16.
  environment.etc."coredns/zones/db.28.10".text = ''
    $ORIGIN 28.10.in-addr.arpa.
    $TTL 3600

    @       IN SOA  sparkle.lunaire.moe. hostmaster.lunaire.moe. (
                    2026040301 ; serial — format YYYYMMDDnn, bump on every zone change
                    3600       ; refresh
                    900        ; retry
                    604800     ; expire
                    86400      ; minimum
            )

    @       IN NS   sparkle.lunaire.moe.

    25.32   IN PTR  sparkle.lunaire.moe.
    96.64   IN PTR  camellya.lunaire.moe.
  '';

  services.coredns = {
    enable = true;
    config = ''
      lunaire.moe {
        file /etc/coredns/zones/db.lunaire.moe
        log
        errors
      }

      28.10.in-addr.arpa {
        file /etc/coredns/zones/db.28.10
        log
        errors
      }

      # Forward all other queries to Cloudflare over DNS-over-TLS (DoT).
      # tls_servername is required to verify the server certificate.
      . {
        forward . tls://1.1.1.1 tls://1.0.0.1 {
          tls_servername cloudflare-dns.com
        }
        cache 3600
        log
        errors
      }
    '';
  };
}
