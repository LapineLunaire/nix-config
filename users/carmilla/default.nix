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
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU="
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMqXDPM9z04YBOp2fVDox7sgPFNpad+9p8UA+od8V8nxAAAACnNzaDpsYXBpbmU="
      ];
    };

  home-manager.users.carmilla = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      ./desktop.nix
      ./packages.nix
      ./programs.nix
      ./services.nix
    ];

    options.userConfig = {
      desktop.enable = lib.mkEnableOption "desktop environment configuration";
      darwin.enable = lib.mkEnableOption "darwin machine configuration";
    };

    config = lib.mkMerge [
      {
        home = {
          username = "carmilla";
          homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "/Users/carmilla"
            else "/home/carmilla";
          stateVersion = "26.05";
        };

        programs.home-manager.enable = true;
      }

      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.sessionVariables = {
          PAGER = "nvimpager";
          MANPAGER = "nvimpager";
        };

        systemd.user.startServices = "sd-switch";
      })
    ];
  };
}
