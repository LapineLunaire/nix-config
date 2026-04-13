{...}: {
  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant@sha256:4c940155cfd5b0187a6faee2db5d52b98bb573edc1aeee95d0818bb17b6534d7";
    autoStart = true;
    volumes = [
      "/persist/var/lib/hass:/config"
    ];
    environment.TZ = "Etc/UTC";
    ports = ["127.0.0.1:7000:7000"];
    # Pass through the Zigbee USB coordinator dongle.
    extraOptions = [
      "--device=/dev/ttyUSB0:/dev/ttyUSB0"
    ];
  };
}
