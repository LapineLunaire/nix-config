{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "carmilla-password-hash".neededForUsers = true;

      "smtp-password" = {};
      "wireguard-private-key" = {};
      "network/ipmi0-mac" = {};
      "network/sfp0-mac" = {};
      "network/sfp1-mac" = {};
      "borg-passphrase" = {};
      "borg-ssh-key" = {};
      "borg-repo" = {};
      # Full known_hosts line for the storage box. Get it with: ssh-keyscan -p 23 <hostname>
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
  };

  environment.etc = {
    "systemd/network/10-ipmi0.link".source = config.sops.templates."10-ipmi0.link".path;
    "systemd/network/10-sfp0.link".source = config.sops.templates."10-sfp0.link".path;
    "systemd/network/10-sfp1.link".source = config.sops.templates."10-sfp1.link".path;
  };
}
