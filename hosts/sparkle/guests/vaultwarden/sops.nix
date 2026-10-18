{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."vaultwarden-db-password".sopsFile = ./database.yaml;
    secrets."vaultwarden-admin-token" = {};
    secrets."vaultwarden-smtp-password" = {
      sopsFile = ../../smtp.yaml;
      key = "smtp-password";
    };
  };
}
