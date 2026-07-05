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
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=2G"
      "mode=755"
    ];
  };

  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=16G"
      "mode=1777"
      "nosuid"
      "nodev"
      "noexec"
    ];
  };

  fileSystems."/var/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=16G"
      "mode=1777"
      "nosuid"
      "nodev"
      "noexec"
    ];
  };

  # LUKS2 container "cryptroot" holds an LVM VG "camellya" with xfs volumes for /nix, /persist, and /home.
  # tpm2-device=auto unlocks from the TPM2 token in the LUKS header, with the passphrase keyslot as fallback.
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/d72ac9db-b522-4087-8352-fdf216090ed5";
    crypttabExtraOpts = ["tpm2-device=auto"];
    allowDiscards = true;
  };

  boot.initrd.supportedFilesystems = ["xfs"];

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/c15c5510-5098-41f0-b292-65b9cea700e1";
    fsType = "xfs";
    options = ["noatime"];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/5937a495-830f-4f76-bca2-1124487ce8c1";
    fsType = "xfs";
    options = ["noatime"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/213e2b4b-5f4e-400f-9b43-fd828e5894ca";
    fsType = "xfs";
    options = ["noatime"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/15B1-29E4";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    # Required for Wayland; also needed by KMS/DRM-based compositors generally.
    modesetting.enable = true;
    # Blackwell (RTX 50-series) requires the open kernel modules; the proprietary modules don't support it.
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
  };
}
