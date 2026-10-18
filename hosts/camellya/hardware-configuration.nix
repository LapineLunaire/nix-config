{
  config,
  lib,
  ...
}: {
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = ["kvm-amd"];

  # LUKS -> LVM -> XFS volumes for /nix, /persist and /home.
  # Use the enrolled TPM token; the LUKS passphrase remains available for recovery.
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/d72ac9db-b522-4087-8352-fdf216090ed5";
    crypttabExtraOpts = ["tpm2-device=auto"];
    allowDiscards = true;
  };

  fileSystems = let
    temporary = {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=16G" "mode=1777" "nosuid" "nodev" "noexec"];
    };
  in {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=2G"
        "mode=755"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/c15c5510-5098-41f0-b292-65b9cea700e1";
      fsType = "xfs";
      options = ["noatime"];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/5937a495-830f-4f76-bca2-1124487ce8c1";
      fsType = "xfs";
      options = ["noatime" "nosuid" "nodev"];
      neededForBoot = true;
    };

    "/home" = {
      device = "/dev/disk/by-uuid/213e2b4b-5f4e-400f-9b43-fd828e5894ca";
      fsType = "xfs";
      options = ["noatime" "nosuid" "nodev"];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/15B1-29E4";
      fsType = "vfat";
      options = ["umask=0077"];
    };

    "/tmp" = temporary;
    "/var/tmp" = temporary;
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.nvidia = {
    modesetting.enable = true;
    # Blackwell requires the open kernel modules.
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    powerManagement.enable = true;
  };
}
