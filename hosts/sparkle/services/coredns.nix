{...}: {
  networking.firewall = {
    allowedUDPPorts = [53];
    allowedTCPPorts = [53];
  };

  environment.etc."coredns/zones/db.lunaire.moe".text = ''
    $ORIGIN lunaire.moe.
    $TTL 3600

    @       IN SOA  sparkle.lunaire.moe. hostmaster.lunaire.moe. (
                    2025010101 ; serial
                    3600       ; refresh
                    900        ; retry
                    604800     ; expire
                    86400      ; minimum
            )

    @       IN NS   sparkle.lunaire.moe.

    sparkle IN A    10.28.32.25
    git     IN CNAME sparkle.lunaire.moe.
    qbt     IN CNAME sparkle.lunaire.moe.
    pga     IN CNAME sparkle.lunaire.moe.
    vw      IN CNAME sparkle.lunaire.moe.
  '';

  environment.etc."coredns/zones/db.28.10".text = ''
    $ORIGIN 28.10.in-addr.arpa.
    $TTL 3600

    @       IN SOA  sparkle.lunaire.moe. hostmaster.lunaire.moe. (
                    2025010101 ; serial
                    3600       ; refresh
                    900        ; retry
                    604800     ; expire
                    86400      ; minimum
            )

    @       IN NS   sparkle.lunaire.moe.

    25.32   IN PTR  sparkle.lunaire.moe.
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
