{
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "usbhid"
    "sr_mod"
  ];

  host.tmpfs = {
    rootSize = "2G";
    tmpSize = "4G";
  };

  fileSystems = {
    "/nix" = {
      device = "sparxie/nix";
      fsType = "zfs";
      options = ["zfsutil"];
    };

    "/persist" = {
      device = "sparxie/persist";
      fsType = "zfs";
      options = ["zfsutil" "nosuid" "nodev"];
      neededForBoot = true;
    };

    "/home" = {
      device = "sparxie/home";
      fsType = "zfs";
      options = ["zfsutil" "nosuid" "nodev"];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/BCA2-56F9";
      fsType = "vfat";
      options = ["umask=0077"];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
