{config, ...}: {
  programs.nh = {
    enable = true;
    flake = config.host.flakePath;
    clean = {
      enable = true;
      extraArgs = "--keep 3";
      interval = [
        {
          Hour = 0;
          Minute = 0;
        }
      ];
    };
  };
}
