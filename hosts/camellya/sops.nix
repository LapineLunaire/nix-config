{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;

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
