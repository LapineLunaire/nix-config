{
  config,
  lib,
  ...
}: {
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "mpt3sas" "nvme" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=2G" "mode=755"];
  };

  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=4G" "mode=1777"];
  };

  fileSystems."/nix" = {
    device = "sparkle/nix";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  fileSystems."/persist" = {
    device = "sparkle/persist";
    fsType = "zfs";
    options = ["zfsutil"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "sparkle/home";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  fileSystems."/mnt/samba/lapine" = {
    device = "vault/lapine";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  fileSystems."/mnt/samba/torrents" = {
    device = "vault/torrents";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B8BB-F5FD";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
