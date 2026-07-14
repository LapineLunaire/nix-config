{...}: {
  imports = [../../docker-common.nix];

  microvm = {
    vcpu = 2;
    mem = 2048;
    initialBalloonMem = 512;
    # Caps the guest physical address width at the VT-d aperture (39 bits on this platform). cloud-hypervisor otherwise sizes the guest address space from the host CPU's phys bits (capped at 46) and places the passed-through controller's 64-bit BAR above what the IOMMU can map, failing at boot with IommuDmaMap EINVAL.
    cloud-hypervisor.extraArgs = ["--cpus" "max_phys_bits=39"];
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
        bus = "pci";
        # The PCH xHCI controller with the Zigbee stick, passed through via VFIO; the guest cp210x driver exposes the stick as ttyUSB0.
        path = "0000:00:14.0";
      }
    ];
  };

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant@sha256:1476924357b46e80735c13e94232ba5c853cac052e9df4bb28d50fa56348097b";
    autoStart = true;
    volumes = ["/persist/var/lib/hass:/config"];
    environment.TZ = "Etc/UTC";
    extraOptions = [
      "--device=/dev/ttyUSB0:/dev/ttyUSB0"
      "--network=host"
    ];
  };

  microvmGuest.hostIngressTCPPorts = [8123];
}
