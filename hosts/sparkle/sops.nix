{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "carmilla-password-hash".neededForUsers = true;

      "cloudflare-dns-api-token" = {};
      "smtp-password" = {};
      "wireguard-private-key" = {};
      "network/ipmi0-mac" = {};
      "network/sfp0-mac" = {};
      "network/sfp1-mac" = {};
      "borg-passphrase" = {};
      "borg-ssh-key" = {};
      "borg-repo" = {};
      "borg-known-hosts" = {};
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

    # Full known_hosts line for the storage box.
    # Get it with: ssh-keyscan -p 23 <hostname>
    templates."borg-known-hosts".content = ''
      ${config.sops.placeholder."borg-known-hosts"}
    '';
  };

  environment.etc = {
    "systemd/network/10-ipmi0.link".source = config.sops.templates."10-ipmi0.link".path;
    "systemd/network/10-sfp0.link".source = config.sops.templates."10-sfp0.link".path;
    "systemd/network/10-sfp1.link".source = config.sops.templates."10-sfp1.link".path;
  };
}
