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

  # LUKS -> btrfs subvolumes for /nix, /persist and /home.
  # Use the enrolled TPM token; the LUKS passphrase remains available for recovery.
  # Unlocking extends PCR 15. The TPM token is bound to its initial value, so it cannot be unsealed after any volume is unlocked.
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/camellya-crypt";
    crypttabExtraOpts = ["tpm2-device=auto" "tpm2-measure-pcr=yes"];
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
      device = "/dev/disk/by-partlabel/camellya-efi";
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
