{...}: {
  services.postgresql = {
    enable = true;
    ensureDatabases = ["forgejo" "vaultwarden"];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
      {
        name = "vaultwarden";
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
      # Allow containerized services and pgAdmin to connect locally
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
    '';
  };
}
