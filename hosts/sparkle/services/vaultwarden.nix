{config, ...}: {
  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:latest";
    autoStart = true;
    environment = {
      DOMAIN = "https://vw.lunaire.moe";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = "6000";
      SIGNUPS_ALLOWED = "false";
    };
    environmentFiles = [
      config.sops.templates."vaultwarden.env".path
    ];
    volumes = [
      "/persist/var/lib/vaultwarden:/data"
    ];
    extraOptions = [
      "--network=host"
    ];
  };
}
