{lib, ...}: {
  microvm = {
    hypervisor = lib.mkForce "qemu";
    vcpu = 2;
    mem = 2560;
    vsock.cid = 14;
    interfaces = [
      {
        type = "tap";
        id = "homeassistant";
        mac = "02:00:00:00:00:14";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/homeassistant";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
    volumes = [
      {
        image = "/persist/vms/homeassistant/volumes/docker.img";
        mountPoint = "/var/lib/docker";
        size = 10240;
        fsType = "xfs";
      }
    ];
    devices = [
      {
        bus = "usb";
        path = "vendorid=0x10c4,productid=0xea60";
      }
    ];
  };
  networking.hostName = "homeassistant";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.14";
      prefixLength = 24;
    }
  ];

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant@sha256:4c940155cfd5b0187a6faee2db5d52b98bb573edc1aeee95d0818bb17b6534d7";
    autoStart = true;
    volumes = ["/persist/var/lib/hass:/config"];
    environment.TZ = "Etc/UTC";
    extraOptions = ["--device=/dev/ttyUSB0:/dev/ttyUSB0" "--network=host"];
  };

  # udev rule to ensure the Zigbee stick is accessible by the container runtime.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
  '';

  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 8123 accept
  '';
}
