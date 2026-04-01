{
  inputs,
  lib,
  pkgs,
  ...
}: let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  programs.zsh.enable = true;

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
      interval.Weekday = 0;
      options = "--delete-older-than 30d";
    };
  };

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
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
