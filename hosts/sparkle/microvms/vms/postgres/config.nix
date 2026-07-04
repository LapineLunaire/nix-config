{
  config,
  lib,
  pkgs,
  ...
}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 3072;
    initialBalloonMem = 1024;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1,${net.ip.postgres}";
      shared_buffers = "512MB";
      effective_cache_size = "1536MB";
      max_connections = 50;
    };
    ensureDatabases = [
      "authelia"
      "forgejo"
      "vaultwarden"
    ];
    ensureUsers = [
      {
        name = "authelia";
        ensureDBOwnership = true;
      }
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
      {
        name = "carmilla";
        ensureClauses.superuser = true;
      }
    ];
    authentication = ''
      local all             postgres                        peer
      host  authelia        authelia    ${net.ip.authelia}/32 scram-sha-256
      host  forgejo         forgejo     ${net.ip.forgejo}/32 scram-sha-256
      host  vaultwarden     vaultwarden ${net.ip.vaultwarden}/32 scram-sha-256
      host  all             carmilla    ${net.ip.pgadmin}/32 scram-sha-256
    '';
  };

  sops.templates."pg-passwords.sql".content = ''
    ALTER USER authelia    WITH PASSWORD '${config.sops.placeholder."authelia-db-password"}';
    ALTER USER forgejo     WITH PASSWORD '${config.sops.placeholder."forgejo-db-password"}';
    ALTER USER vaultwarden WITH PASSWORD '${config.sops.placeholder."vaultwarden-db-password"}';
  '';

  systemd.services.postgresql-passwords = {
    description = "Set PostgreSQL user passwords from sops secrets";
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = "${config.services.postgresql.package}/bin/psql -f ${config.sops.templates."pg-passwords.sql".path}";
    };
  };

  networking.firewall.extraInputRules = ''
    ip saddr { ${lib.concatStringsSep ", " (map (name: net.ip.${name}) net.postgresClients)} } tcp dport 5432 accept
  '';
}
