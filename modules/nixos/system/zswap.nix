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
    # Not combined with zram: zswap would only compress pages on their way into it.
    # The shrinker writes cold pages to disk before the compressed pool fills up.
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.shrinker_enabled=1"
    ];

    # NixOS creates the file with btrfs mkswapfile, so it works despite the subvolume's compression.
    # The /persist subvolume cannot be snapshotted while the swap file is in use.
    swapDevices = [
      {
        device = "/persist/swapfile";
        size = config.host.swapFileSize * 1024;
      }
    ];
  };
}
