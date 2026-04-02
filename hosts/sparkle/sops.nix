{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "carmilla-password-hash" = {
        neededForUsers = true;
      };
      "cloudflare-dns-api-token" = {};
      "forgejo-runner-token" = {};
      "network/ipmi0-mac" = {};
      "network/sfp0-mac" = {};
      "network/sfp1-mac" = {};
      "pgadmin-password" = {};
      "protonvpn-qbittorrent-conf" = {};
      "vaultwarden-admin-token" = {};
      "vaultwarden-db-password" = {};
    };

    templates."10-ipmi0.link".content = ''
      [Match]
      MACAddress=${config.sops.placeholder."network/ipmi0-mac"}

      [Link]
      Name=ipmi0
    '';
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
    templates."cloudflare-dns-api-token.env" = {
      content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-dns-api-token"}
      '';
      owner = "acme";
    };

    templates."forgejo-runner-token.env".content = ''
      TOKEN=${config.sops.placeholder."forgejo-runner-token"}
    '';

    templates."pgadmin.env".content = ''
      PGADMIN_DEFAULT_PASSWORD=${config.sops.placeholder."pgadmin-password"}
    '';

    templates."vaultwarden.env".content = ''
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}
      DATABASE_URL=postgresql://vaultwarden:${config.sops.placeholder."vaultwarden-db-password"}@10.28.32.25/vaultwarden
    '';
  };

  environment.etc = {
    "systemd/network/10-ipmi0.link".source = config.sops.templates."10-ipmi0.link".path;
    "systemd/network/10-sfp0.link".source = config.sops.templates."10-sfp0.link".path;
    "systemd/network/10-sfp1.link".source = config.sops.templates."10-sfp1.link".path;
  };
}
