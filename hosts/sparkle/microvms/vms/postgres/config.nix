{
  config,
  lib,
  ...
}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 3072;
    initialBalloonMem = 1024;
    vsock.cid = 10;
    interfaces = [
      {
        type = "tap";
        id = "postgres";
        mac = "02:00:00:00:00:10";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/postgres";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };
  networking.hostName = "postgres";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.10";
      prefixLength = 24;
    }
  ];

  services.postgresql = {
    enable = true;
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1,10.28.34.10";
      shared_buffers = "512MB";
      effective_cache_size = "1536MB";
      max_connections = 50;
    };
    ensureDatabases = ["authelia" "forgejo" "vaultwarden"];
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
      local all             postgres                        trust
      host  authelia        authelia    10.28.34.11/32 scram-sha-256
      host  forgejo         forgejo     10.28.34.12/32 scram-sha-256
      host  vaultwarden     vaultwarden 10.28.34.16/32 scram-sha-256
      host  all             carmilla    10.28.34.20/32 scram-sha-256
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
    ip saddr { 10.28.34.11, 10.28.34.12, 10.28.34.16, 10.28.34.18, 10.28.34.20 } tcp dport 5432 accept
  '';
}
