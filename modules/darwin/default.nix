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
}
