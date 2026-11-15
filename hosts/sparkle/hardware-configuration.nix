{
  config,
  lib,
  ...
}: {
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = ["kvm-intel"];

  host.tmpfs = {
    rootSize = "2G";
    tmpSize = "4G";
  };

  fileSystems = {
    "/nix" = {
      device = "sparkle/nix";
      fsType = "zfs";
      options = ["zfsutil"];
    };

    "/persist" = {
      device = "sparkle/persist";
      fsType = "zfs";
      options = ["zfsutil" "nosuid" "nodev"];
      neededForBoot = true;
    };

    "/home" = {
      device = "sparkle/home";
      fsType = "zfs";
      options = ["zfsutil" "nosuid" "nodev"];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/B8BB-F5FD";
      fsType = "vfat";
      options = ["umask=0077"];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
