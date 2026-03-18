{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.carmilla = {
    isNormalUser = true;
    description = "Carmilla";
    uid = 1000;
    shell = pkgs.zsh;
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

  home-manager.users.carmilla = {lib, ...}: {
    imports = [
      ./desktop.nix
      ./packages.nix
      ./programs.nix
      ./services.nix
    ];

    options.userConfig = {
      desktop.enable = lib.mkEnableOption "desktop environment configuration";
    };

    config = {
      home = {
        username = "carmilla";
        homeDirectory = "/home/carmilla";
        stateVersion = "26.05";

        sessionVariables = {
          PAGER = "nvimpager";
          MANPAGER = "nvimpager";
        };
      };

      programs.home-manager.enable = true;

      systemd.user.startServices = "sd-switch";
    };
  };
}
