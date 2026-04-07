{...}: {
  imports = [../../modules/darwin];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;

  networking = {
    hostName = "silverwolf";
    computerName = "Silver Wolf";
  };
  system.primaryUser = "carmilla";

  homebrew = {
    enable = true;
    enableZshIntegration = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Remove casks not listed here on activation, keeping the install declarative.
      cleanup = "uninstall";
    };
    # Prevent Homebrew from auto-updating during regular brew commands; updates happen only on nix-darwin activation.
    global.autoUpdate = false;
    casks = [
      "altserver"
      "appcleaner"
      "linearmouse"
      "ghostty"
      "obs"
      "playcover-community"
      "prismlauncher"
      "proton-drive"
      "soundsource"
      "steam"
      "tidal"
      "wootility"
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
