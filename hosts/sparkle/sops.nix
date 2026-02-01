{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "network/sfp0-mac" = {};
      "network/sfp1-mac" = {};
      "network/ipmi0-mac" = {};
      "cloudflare-dns-api-token" = {owner = "acme";};
      "pgadmin-password" = {};
      "protonvpn-qbittorrent-conf" = {};
    };

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
  };

  environment.etc = {
    "systemd/network/10-sfp0.link".source = config.sops.templates."10-sfp0.link".path;
    "systemd/network/10-sfp1.link".source = config.sops.templates."10-sfp1.link".path;
    "systemd/network/10-ipmi0.link".source = config.sops.templates."10-ipmi0.link".path;
  };
}
