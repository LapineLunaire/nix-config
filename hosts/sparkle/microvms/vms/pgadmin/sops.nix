{...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."pgadmin-password" = {};
    secrets."pgadmin-oidc-client-secret" = {};
    templates."pgadmin.env" = {};
  };
}
