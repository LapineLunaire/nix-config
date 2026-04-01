{...}: {
  imports = [../../modules/darwin];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;

  networking.hostName = "silverwolf";
  networking.computerName = "Silver Wolf";
  system.primaryUser = "carmilla";

  homebrew = {
    enable = true;
    enableZshIntegration = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    global.autoUpdate = false;
    taps = [];
    brews = [];
    casks = [
      "appcleaner"
      "ghostty"
      "obs"
      "playcover-community"
      "prismlauncher"
      "proton-drive"
      "soundsource"
      "steam"
      "tidal"
    ];
    masApps = {
      "AdGuard Mini" = 1440147259;
      "Amphetamine" = 937984704;
      "Bitwarden" = 1352778147;
      "Monal" = 1637078500;
      "WireGuard" = 1451685025;
      "Xcode" = 497799835;
    };
  };
}
