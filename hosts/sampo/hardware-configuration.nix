{lib, ...}: {
  boot.initrd.availableKernelModules = ["sd_mod" "sr_mod"];

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

  fileSystems."/persist" = {
    device = "sampo/nixos";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "sampo/nix";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "sampo/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1FD6-2B0A";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  # Using zramSwap instead, ZFS swap partitions can deadlock
  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.hypervGuest.enable = true;
}
