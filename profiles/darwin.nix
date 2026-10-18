{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/shared/host.nix
    ../modules/shared/nix-settings.nix
    ../modules/darwin/homebrew.nix
    ../modules/darwin/nh.nix
  ];

  programs.zsh.enable = true;
  environment.systemPackages = [pkgs.ghostty-bin.terminfo];
  security.pam.services.sudo_local.touchIdAuth = true;
  time.timeZone = lib.mkDefault "Europe/Amsterdam";

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.springing.enabled" = true;
      AppleICUForce24HourTime = true;
      NSWindowShouldDragOnGesture = true;
    };

    loginwindow.GuestEnabled = false;

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
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
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    screencapture = {
      location = "~/Pictures/Screenshots";
      disable-shadow = true;
    };

    trackpad.Clicking = true;

    menuExtraClock = {
      Show24Hour = true;
      ShowDayOfWeek = true;
    };

    WindowManager = {
      HideDesktop = true;
      EnableTiledWindowMargins = false;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = false;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
