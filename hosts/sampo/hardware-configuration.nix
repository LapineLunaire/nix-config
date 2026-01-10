{lib, ...}: {
  boot.initrd.availableKernelModules = ["sd_mod" "sr_mod"];

  fileSystems."/" = {
    device = "sampo/nixos";
    fsType = "zfs";
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
    options = ["fmask=0022" "dmask=0022"];
  };

  # Using zramSwap instead, ZFS swap partitions can deadlock
  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.hypervGuest.enable = true;
}
