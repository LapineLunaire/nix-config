{
  # Refuse to import a root pool still held by another system.
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 3;
    };
  };
}
