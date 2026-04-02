{...}: {
  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    autoStart = true;
    volumes = [
      "/persist/var/lib/hass:/config"
    ];
    environment.TZ = "Etc/UTC";
    ports = ["127.0.0.1:7000:7000"];
    extraOptions = [
      "--device=/dev/ttyUSB0:/dev/ttyUSB0"
    ];
  };
}
