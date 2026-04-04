{...}: {
  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant@sha256:8848691147f01a6eee7753de2ade21b04d6168fcd2e2a7089f6f84e3b7b86960";
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
