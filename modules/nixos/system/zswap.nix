{
  config,
  lib,
  ...
}: {
  options.host.swapFileSize = lib.mkOption {
    type = lib.types.ints.positive;
    description = "Size of the disk swap file in GiB.";
  };

  config = {
    # Keep swapped-out pages compressed in RAM.
    # The shrinker lets memory pressure move cold ones to the swap file without waiting for the pool to fill up.
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.shrinker_enabled=1"
    ];

    # 100 tells the kernel that swapping costs as much as rereading files; 120, two thirds as much.
    # A cautious value: pages in the compressed pool come back several times faster than a disk read,
    # but the ones already moved to the swap file do not.
    boot.kernel.sysctl."vm.swappiness" = 120;

    # NixOS creates the file with btrfs filesystem mkswapfile, so the subvolume's compression and copy-on-write do not apply to it.
    # Btrfs cannot snapshot /persist while the swap file is active.
    swapDevices = [
      {
        device = "/persist/swapfile";
        size = config.host.swapFileSize * 1024;
      }
    ];
  };
}
