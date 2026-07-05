{lib, ...}: let
  zigbee = import ../../../zigbee-stick.nix;
in {
  imports = [../../docker-common.nix];

  microvm = {
    # qemu instead of the cloud-hypervisor default: the Zigbee stick USB passthrough (devices below) needs it. This is the only VM not on cloud-hypervisor.
    hypervisor = lib.mkForce "qemu";
    vcpu = 2;
    mem = 2560;
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
        path = "vendorid=0x${zigbee.vendorId},productid=0x${zigbee.productId}";
      }
    ];
  };

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant@sha256:adb3341e31e03e0048e60d8c1cf952e118a381ae258bb921d3da12a3b27bf0c2";
    autoStart = true;
    volumes = ["/persist/var/lib/hass:/config"];
    environment.TZ = "Etc/UTC";
    extraOptions = [
      "--device=/dev/ttyUSB0:/dev/ttyUSB0"
      "--network=host"
    ];
  };

  # udev rule to ensure the Zigbee stick is accessible by the container runtime.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="${zigbee.vendorId}", ATTRS{idProduct}=="${zigbee.productId}", GROUP="dialout", MODE="0660"
  '';

  microvmGuest.hostIngressTCPPorts = [8123];
}
