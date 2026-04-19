{...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."authelia-db-password" = {};
    secrets."forgejo-db-password" = {};
    secrets."vaultwarden-db-password" = {};
    templates."pg-passwords.sql".owner = "postgres";
  };
}
