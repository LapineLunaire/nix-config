{...}: {
  services.postgresql = {
    enable = true;
    ensureDatabases = ["ejabberd"];
    ensureUsers = [
      {
        name = "ejabberd";
        ensureDBOwnership = true;
      }
      {
        name = "lapine";
        ensureClauses.superuser = true;
      }
    ];
    authentication = ''
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
    '';
  };

  services.redis.servers."" = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
  };
}
