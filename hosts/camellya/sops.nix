{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "samba-username" = {};
      "samba-password" = {};
    };

    templates."samba-credentials".content = ''
      username=${config.sops.placeholder."samba-username"}
      password=${config.sops.placeholder."samba-password"}
    '';
  };
}
