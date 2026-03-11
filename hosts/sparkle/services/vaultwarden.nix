{config, ...}: {
  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:latest";
    autoStart = true;
    environment = {
      DOMAIN = "https://vw.lunaire.moe";
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = "6000";
      SIGNUPS_ALLOWED = "false";
    };
    environmentFiles = [
      config.sops.templates."vaultwarden.env".path
    ];
    volumes = [
      "/persist/var/lib/vaultwarden:/data"
    ];
    ports = ["127.0.0.1:6000:6000"];
  };
}
