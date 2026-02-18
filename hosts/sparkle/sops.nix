{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "network/sfp0-mac" = {};
      "network/sfp1-mac" = {};
      "network/ipmi0-mac" = {};
      "cloudflare-dns-api-token" = {};
      "pgadmin-password" = {};
      "protonvpn-qbittorrent-conf" = {};
      "vaultwarden-admin-token" = {};
      "vaultwarden-db-password" = {};
      "forgejo-runner-token" = {};
    };

    templates."forgejo-runner-token.env".content = "TOKEN=${config.sops.placeholder."forgejo-runner-token"}\n";

    templates."vaultwarden.env".content = "ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}\nDATABASE_URL=postgresql://vaultwarden:${config.sops.placeholder."vaultwarden-db-password"}@127.0.0.1/vaultwarden\n";

    templates."pgadmin.env".content = "PGADMIN_DEFAULT_PASSWORD=${config.sops.placeholder."pgadmin-password"}\n";

    templates."10-sfp0.link".content = ''
      [Match]
      MACAddress=${config.sops.placeholder."network/sfp0-mac"}

      [Link]
      Name=sfp0
    '';
    templates."10-sfp1.link".content = ''
      [Match]
      MACAddress=${config.sops.placeholder."network/sfp1-mac"}

      [Link]
      Name=sfp1
    '';
    templates."10-ipmi0.link".content = ''
      [Match]
      MACAddress=${config.sops.placeholder."network/ipmi0-mac"}

      [Link]
      Name=ipmi0
    '';
    templates."cloudflare-dns-api-token.env" = {
      content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-dns-api-token"}
      '';
      owner = "acme";
    };
  };

  environment.etc = {
    "systemd/network/10-sfp0.link".source = config.sops.templates."10-sfp0.link".path;
    "systemd/network/10-sfp1.link".source = config.sops.templates."10-sfp1.link".path;
    "systemd/network/10-ipmi0.link".source = config.sops.templates."10-ipmi0.link".path;
  };
}
