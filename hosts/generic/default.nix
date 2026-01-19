{...}: {
  imports = [
    ./packages.nix
    ./security.nix
    ./services.nix
  ];

  config = {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 30;
      priority = 100;
    };

    time.timeZone = "Europe/Amsterdam";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_TIME = "C.UTF-8";
        LC_MONETARY = "nl_NL.UTF-8";
        LC_MEASUREMENT = "nl_NL.UTF-8";
        LC_PAPER = "nl_NL.UTF-8";
      };
    };

    console.font = "Lat2-Terminus16";
  };
}
