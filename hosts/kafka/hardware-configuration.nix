{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "usbhid"];
  boot.initrd.kernelModules = ["i915"];
  boot.kernelModules = ["kvm-intel"];

  # Unlocking extends PCR 15. The TPM token is bound to its initial value, so it cannot be unsealed after any volume is unlocked.
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/kafka-crypt";
    crypttabExtraOpts = ["tpm2-device=auto" "tpm2-measure-pcr=yes"];
    allowDiscards = true;
  };

  host.tmpfs = {
    rootSize = "2G";
    tmpSize = "4G";
  };

  fileSystems = {
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = ["subvol=@nix" "compress=zstd:3" "noatime"];
    };
    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = ["subvol=@persist" "compress=zstd:3" "noatime" "nosuid" "nodev"];
      neededForBoot = true;
    };
    "/home" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = ["subvol=@home" "compress=zstd:3" "noatime" "nosuid" "nodev"];
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/kafka-efi";
      fsType = "vfat";
      options = ["umask=0077"];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.graphics.extraPackages = [pkgs.intel-media-driver];
}
