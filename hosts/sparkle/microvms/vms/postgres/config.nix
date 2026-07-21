{
  config,
  lib,
  outputs,
  pkgs,
  ...
}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix outputs.nixosModules.postgres-passwords];

  microvm = {
    vcpu = 2;
    mem = 3072;
    initialBalloonMem = 1024;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1,${net.vmAddress.postgres}";
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
      host  authelia        authelia    ${net.vmAddress.authelia}/32 scram-sha-256
      host  forgejo         forgejo     ${net.vmAddress.forgejo}/32 scram-sha-256
      host  vaultwarden     vaultwarden ${net.vmAddress.vaultwarden}/32 scram-sha-256
      host  all             carmilla    ${net.vmAddress.pgadmin}/32 scram-sha-256
    '';
  };

  sops.templates."pg-passwords.sql".content = ''
    ALTER USER authelia    WITH PASSWORD '${config.sops.placeholder."authelia-db-password"}';
    ALTER USER forgejo     WITH PASSWORD '${config.sops.placeholder."forgejo-db-password"}';
    ALTER USER vaultwarden WITH PASSWORD '${config.sops.placeholder."vaultwarden-db-password"}';
  '';

  networking.firewall.extraInputRules = ''
    ip saddr { ${lib.concatStringsSep ", " (map (name: net.vmAddress.${name}) net.postgresClients)} } tcp dport 5432 accept
  '';
}
