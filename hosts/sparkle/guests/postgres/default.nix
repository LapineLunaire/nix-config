{
  config,
  net,
  lib,
  pkgs,
  ...
}: {
  imports = [../../../../modules/nixos/services/postgresql-passwords.nix];

  microvm = {
    vcpu = 2;
    mem = 3072;
    initialBalloonMem = 1024;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    settings = {
      # With a specific address, PostgreSQL stays up on loopback alone if eth0 is not ready. The firewall and pg_hba limit clients.
      listen_addresses = lib.mkForce "*";
      port = net.postgresPort;
      shared_buffers = "512MB";
      effective_cache_size = "1536MB";
      max_connections = 50;
    };
    ensureDatabases = net.postgresDatabases;
    ensureUsers =
      map (name: {
        inherit name;
        ensureDBOwnership = true;
      })
      net.postgresDatabases
      ++ [
        {
          name = "carmilla";
          ensureClauses.superuser = true;
        }
      ];
    authentication = let
      apps = lib.concatMapStringsSep "\n" (name: "host  ${name} ${name} ${net.vmAddress.${name}}/32 scram-sha-256") net.postgresDatabases;
    in ''
      local all             postgres                        peer
      ${apps}
      host  all             carmilla    ${net.vmAddress.pgadmin}/32 scram-sha-256
      host  all             all         127.0.0.1/32 scram-sha-256
      host  all             all         ::1/128 scram-sha-256
    '';
  };

  services.postgresql.passwordFiles =
    lib.genAttrs (net.postgresDatabases ++ ["carmilla"]) (name: config.sops.secrets."${name}-db-password".path);

  # Each application's password comes from the file it shares with that application's guest.
  sops = let
    restartUnits = ["postgresql-passwords.service"];
  in {
    defaultSopsFile = ./secrets.yaml;
    secrets =
      lib.listToAttrs (map (name:
        lib.nameValuePair "${name}-db-password" {
          sopsFile = ../${name}/database.yaml;
          inherit restartUnits;
        })
      net.postgresDatabases)
      // {"carmilla-db-password" = {inherit restartUnits;};};
  };

  networking.firewall.extraInputRules = ''
    ip saddr { ${net.postgresClientsNft} } tcp dport ${toString net.postgresPort} accept
  '';
}
