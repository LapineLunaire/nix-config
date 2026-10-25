{
  # Scrubs each btrfs device once, not once per subvolume mount.
  services.btrfs.autoScrub.enable = true;
}
