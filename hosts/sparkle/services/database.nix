{
  lib,
  config,
  ...
}: {
  services.postgresql = {
    enable = true;
    ensureDatabases = ["forgejo"];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
      {
        name = "lapine";
        ensureClauses = {
          superuser = true;
        };
      }
    ];
    authentication = ''
      # Allow pgAdmin to connect locally
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
    '';
  };

  services.pgadmin = {
    enable = true;
    initialEmail = "lapine@lunaire.eu";
    initialPasswordFile = config.sops.secrets."pgadmin-password".path;
    settings = {
      # Listen only on localhost since Caddy will reverse proxy
      DEFAULT_SERVER = "127.0.0.1";
      DEFAULT_SERVER_PORT = lib.mkForce 5000;

      # Pre-configure the local PostgreSQL server
      MASTER_PASSWORD_REQUIRED = false;
    };
  };
}
