{
  imports = [./home.nix];

  users.users.carmilla = {
    home = "/Users/carmilla";
    openssh.authorizedKeys.keys = import ./ssh-keys.nix;
  };

  homebrew = {
    brews = ["container"];
    casks = [
      "altserver"
      "discord"
      "appcleaner"
      "curseforge"
      "moonlight"
      "linearmouse"
      "obs"
      "playcover-community"
      "prismlauncher"
      "proton-drive"
      "proton-mail"
      "protonvpn"
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

  home-manager.users.carmilla = {pkgs, ...}: {
    imports = [./applications.nix];
    home.packages = with pkgs; [iina mtr utm];
  };
}
