{
  config,
  lib,
  ...
}: {
  services.postgresql = {
    enable = true;
    # Also listen on the docker0 gateway so containerized services (pgAdmin) can connect.
    settings.listen_addresses = lib.mkForce "localhost,172.17.0.1";
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
      # Allow localhost and the Docker bridge subnet (172.17.0.0/16) to connect.
      # The Docker subnet is needed for containerized services (pgAdmin).
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
      host all all 172.17.0.0/16 scram-sha-256
    '';
  };

  networking.firewall.interfaces."docker0".allowedTCPPorts = [5432];

  virtualisation.oci-containers.containers.pgadmin = {
    image = "dpage/pgadmin4@sha256:ff557f69d9808085dc3554f56c1b06a36ac8cddabe4485212920b9604261abdb";
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
