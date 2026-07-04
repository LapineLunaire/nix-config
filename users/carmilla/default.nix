{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.carmilla =
    {
      name = "carmilla";
      home =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/Users/carmilla"
        else "/home/carmilla";
      shell = pkgs.zsh;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      isNormalUser = true;
      description = "Carmilla";
      uid = 1000;
      hashedPasswordFile = config.sops.secrets."carmilla-password-hash".path;
      extraGroups =
        ["wheel"]
        ++ lib.optionals config.networking.networkmanager.enable ["networkmanager"]
        ++ lib.optionals config.home-manager.users.carmilla.userConfig.desktop.enable ["video" "audio" "input"];
      openssh.authorizedKeys.keys = import ./ssh-keys.nix;
    };

  home-manager.backupFileExtension = "bak";

  home-manager.users.carmilla = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: {
    imports = [
      ./desktop.nix
      ./packages.nix
      ./programs.nix
    ];

    options.userConfig.desktop.enable = lib.mkEnableOption "desktop environment configuration";

    config = {
      home = {
        username = "carmilla";
        homeDirectory = osConfig.users.users.carmilla.home;
        stateVersion =
          if config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin
          then "26.11"
          else "26.05";
      };

      programs.home-manager.enable = true;

      home.sessionVariables = {
        PAGER = "nvimpager";
        MANPAGER = "nvimpager";
      };

      # Activate new and changed systemd user services on `home-manager switch` without requiring a logout/login cycle.
      systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
    };
  };
}
