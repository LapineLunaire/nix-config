{...}: {
  imports = [
    ./pkgs
    ./security.nix
    ./services
    ./stylix.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = ["ntsync"];
  };

  # dbus-broker is faster and more secure than dbus-daemon
  services.dbus.implementation = "broker";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
    priority = 100;
  };

  time.timeZone = "Europe/Amsterdam";

  # C.UTF-8 gives ISO 8601 date format (YYYY-MM-DD)
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "C.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "colemak";
  };

  # Required for Home Manager XDG portal integration
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
