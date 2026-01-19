{
  config,
  lib,
  inputs,
  ...
}: {
  imports =
    [
      ./packages.nix
      ./security.nix
      ./services.nix
    ]
    ++ lib.optionals config.hostConfig.desktop.enable [
      ./desktop.nix
      ./stylix.nix
    ];

  options.hostConfig.desktop.enable = lib.mkEnableOption "desktop environment support";

  config = {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    boot.kernelModules = lib.optionals config.hostConfig.desktop.enable ["ntsync"];

    nix.settings =
      {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
      }
      // lib.optionalAttrs config.hostConfig.desktop.enable inputs.aagl.nixConfig;

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
    console.keyMap = lib.mkIf config.hostConfig.desktop.enable "colemak";

    environment.sessionVariables = lib.mkIf config.hostConfig.desktop.enable {
      PROTON_ENABLE_WAYLAND = "1";
      PROTON_ENABLE_HDR = "1";
      FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
    };

    environment.pathsToLink = lib.optionals config.hostConfig.desktop.enable [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
  };
}
