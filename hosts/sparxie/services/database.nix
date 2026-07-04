{
  config,
  pkgs,
  ...
}: {
  imports = [../../../modules/nixos/postgres-passwords.nix];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    ensureDatabases = ["ejabberd"];
    ensureUsers = [
      {
        name = "ejabberd";
        ensureDBOwnership = true;
      }
      {
        name = "carmilla";
        ensureClauses.superuser = true;
      }
    ];
    authentication = ''
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
    '';
  };

  # ensureUsers creates the ejabberd role without a password, but pg_hba requires scram-sha-256 over TCP, so set it from sops.
  sops.templates."pg-passwords.sql" = {
    owner = "postgres";
    content = ''
      ALTER USER ejabberd WITH PASSWORD '${config.sops.placeholder."ejabberd-sql-password"}';
    '';
  };

  # ejabberd uses Redis for session and cache storage (db 1, configured in ejabberd.yml).
  services.redis.servers."" = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
    requirePassFile = config.sops.secrets."redis-password".path;
  };
}
