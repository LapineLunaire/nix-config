{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./account.nix];

  # Full workstation/server user: extends the minimal account with an interactive shell, the login password, desktop-only groups, and home-manager.
  users.users.carmilla =
    {
      shell = pkgs.zsh;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      hashedPasswordFile = config.sops.secrets."carmilla-password-hash".path;
      extraGroups =
        lib.optionals config.networking.networkmanager.enable ["networkmanager"]
        ++ lib.optionals config.home-manager.users.carmilla.userConfig.desktop.enable ["video" "audio" "input"];
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

    options.userConfig = {
      desktop.enable = lib.mkEnableOption "desktop environment configuration";
      # GUI machines: Linux desktops plus all darwin hosts. Derived from the two flags above, do not set directly.
      gui = lib.mkOption {
        type = lib.types.bool;
        readOnly = true;
        default = config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin;
      };
    };

    config = {
      home = {
        username = "carmilla";
        homeDirectory = osConfig.users.users.carmilla.home;
        # The gui hosts run nixpkgs-unstable (26.11) and the servers run stable (26.05); the split following the gui flag is a coincidence of which hosts run which channel, not a property of the flag.
        stateVersion =
          if config.userConfig.gui
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
