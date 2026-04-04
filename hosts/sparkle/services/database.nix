{config, ...}: {
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
        name = "carmilla";
        ensureClauses.superuser = true;
      }
    ];
    authentication = ''
      # Allow localhost and the Docker bridge subnet (172.17.0.0/16) to connect.
      # The Docker subnet is needed for containerized services (pgAdmin).
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
      host all all 172.17.0.0/16 scram-sha-256
    '';
  };

  networking.firewall.interfaces."docker0".allowedTCPPorts = [5432];

  virtualisation.oci-containers.containers.pgadmin = {
    image = "dpage/pgadmin4:latest";
    autoStart = true;
    environment = {
      PGADMIN_DEFAULT_EMAIL = "lapine@lunaire.eu";
      PGADMIN_LISTEN_PORT = "5000";
    };
    environmentFiles = [
      config.sops.templates."pgadmin.env".path
    ];
    volumes = [
      "/persist/var/lib/pgadmin:/var/lib/pgadmin"
    ];
    ports = ["127.0.0.1:5000:5000"];
  };
}
