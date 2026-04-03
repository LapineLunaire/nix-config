{
  inputs,
  lib,
  pkgs,
  ...
}: let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  programs.zsh.enable = true;

  # Allow Touch ID to authenticate sudo prompts in terminal.
  security.pam.services.sudo_local.touchIdAuth = true;

  time.timeZone = lib.mkDefault "Europe/Amsterdam";

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      flake-registry = "";
      auto-optimise-store = true;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    gc = {
      automatic = true;
      interval.Weekday = 7; # Sunday
      options = "--delete-older-than 30d";
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      # Disable press-and-hold accent menu so key repeat works in all apps.
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
      # Allow dragging windows by clicking anywhere on them (not just the title bar).
      NSWindowShouldDragOnGesture = true;
    };

    loginwindow.GuestEnabled = false;

    CustomUserPreferences = {
      NSGlobalDomain.AppleActionOnDoubleClick = "Minimize";
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      "com.apple.assistant.support"."Assistant Enabled" = false;
      "com.apple.finder" = {
        FXICloudDriveDesktop = false;
        FXICloudDriveDocuments = false;
      };
      "com.apple.SubmitDiagInfo".AutoSubmit = false;
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
      FXDefaultSearchScope = "SCcf"; # search current folder by default
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv"; # list view
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
      # Hide desktop icons so files on ~/Desktop don't clutter the wallpaper.
      HideDesktop = true;
      EnableTiledWindowMargins = false;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
