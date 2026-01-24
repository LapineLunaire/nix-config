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

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
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

  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    settings = {
      server = {
        DOMAIN = "git.lunaire.moe";
        ROOT_URL = "https://git.lunaire.moe/";
        HTTP_PORT = 3000;
      };
      service.DISABLE_REGISTRATION = true;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = ["forgejo"];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.tmpfiles.rules = [
    "d '${config.services.forgejo.stateDir}' 0750 ${config.services.forgejo.user} ${config.services.forgejo.group} - -"
    "d '${config.services.forgejo.customDir}' 0750 ${config.services.forgejo.user} ${config.services.forgejo.group} - -"
  ];

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "sparkle";
        "netbios name" = "sparkle";
        "security" = "user";
        "hosts allow" = "10.0.0.0/8 127.0.0.0/8 ::1";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      lapine = {
        "path" = "/mnt/samba/lapine";
        "valid users" = "lapine";
        "writeable" = "yes";
        "force user" = "lapine";
        "force group" = "users";
        "create mask" = "0644";
        "directory mask" = "0755";
        "fruit:aapl" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
