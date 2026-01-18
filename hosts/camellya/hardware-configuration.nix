{
  config,
  lib,
  ...
}: {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=2G" "mode=755"];
  };

  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=16G" "mode=1777"];
  };

  fileSystems."/nix" = {
    device = "camellya/nix";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  fileSystems."/persist" = {
    device = "camellya/persist";
    fsType = "zfs";
    options = ["zfsutil"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "camellya/home";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9864-73D6";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
