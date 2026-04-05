{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "carmilla-password-hash".neededForUsers = true;
      "cloudflare-dns-api-token" = {};
      "wireguard-private-key" = {};
      "forgejo-runner-token" = {};
      "forgejo-smtp-password" = {};
      "network/ipmi0-mac" = {};
      "network/sfp0-mac" = {};
      "network/sfp1-mac" = {};
      "authelia-jwt-secret".owner = "authelia-main";
      "authelia-session-secret".owner = "authelia-main";
      "authelia-storage-encryption-key".owner = "authelia-main";
      "authelia-users".owner = "authelia-main";
      "authelia-db-password" = {};
      "authelia-smtp-password" = {};
      "authelia-oidc-hmac-secret".owner = "authelia-main";
      "authelia-oidc-issuer-key".owner = "authelia-main";
      "authelia-forgejo-client-secret-hash" = {};
      "redis-authelia-password".owner = "redis-authelia";
      "smtp-password" = {};
      "pgadmin-password" = {};
      "protonvpn-qbittorrent-conf" = {};
      "vaultwarden-admin-token" = {};
      "vaultwarden-db-password" = {};
      "vaultwarden-smtp-password" = {};
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

    templates."forgejo.env".content = ''
      FORGEJO__mailer__PASSWD=${config.sops.placeholder."forgejo-smtp-password"}
    '';

    templates."pgadmin.env".content = ''
      PGADMIN_DEFAULT_PASSWORD=${config.sops.placeholder."pgadmin-password"}
    '';

    templates."vaultwarden.env".content = ''
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}
      DATABASE_URL=postgresql://vaultwarden:${config.sops.placeholder."vaultwarden-db-password"}@localhost/vaultwarden
      SMTP_HOST=smtp.protonmail.ch
      SMTP_PORT=587
      SMTP_SECURITY=starttls
      SMTP_FROM=noreply@lunaire.eu
      SMTP_FROM_NAME=Vaultwarden
      SMTP_USERNAME=noreply@lunaire.eu
      SMTP_PASSWORD=${config.sops.placeholder."vaultwarden-smtp-password"}
    '';
  };

  environment.etc = {
    "systemd/network/10-ipmi0.link".source = config.sops.templates."10-ipmi0.link".path;
    "systemd/network/10-sfp0.link".source = config.sops.templates."10-sfp0.link".path;
    "systemd/network/10-sfp1.link".source = config.sops.templates."10-sfp1.link".path;
  };
}
