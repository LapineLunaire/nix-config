{...}: {
  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    autoStart = true;
    volumes = [
      "/persist/var/lib/hass:/config"
    ];
    environment = {
      TZ = "Etc/UTC";
    };
    extraOptions = [
      "--network=host"
      "--device=/dev/ttyUSB0:/dev/ttyUSB0"
    ];
  };
}
