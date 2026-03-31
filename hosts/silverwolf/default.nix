{pkgs, ...}: {
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;

  networking.hostName = "silverwolf";
  system.primaryUser = "carmilla";

  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      interval.Weekday = 0;
      options = "--delete-older-than 30d";
    };
  };

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

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
    };

    dock = {
      autohide = true;
      mru-spaces = false;
      tilesize = 64;
      minimize-to-application = true;
      show-recents = false;
    };

    finder = {
      _FXSortFoldersFirst = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
    };

    screencapture.location = "~/Pictures/Screenshots";

    trackpad.Clicking = true;
  };

  home-manager.users.carmilla.userConfig.darwin.enable = true;
}
