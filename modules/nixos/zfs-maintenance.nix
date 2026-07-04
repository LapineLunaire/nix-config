{...}: {
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 4; # every 15 min, keep 4 (1 hour)
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 3;
    };
  };
}
