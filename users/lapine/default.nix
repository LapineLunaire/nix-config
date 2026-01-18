{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    users.users.lapine = {
      isNormalUser = true;
      description = "Lapine";
      shell = pkgs.zsh;
      hashedPassword = "$6$h.m1Ftri0Zjsinfs$jKmYsiTrcWzTOCVGSeKA53p/1twd0buX/qxzS08aB6Dgm7PVl9jQTeiZEmb4MIBWrZHEsyLt/ejQsko4b.abf/";
      extraGroups =
        ["wheel"]
        ++ lib.optionals config.networking.networkmanager.enable ["networkmanager"]
        ++ lib.optionals config.hostConfig.desktop.enable ["video" "audio" "input"];
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU="
      ];
    };

    home-manager.users.lapine = {
      lib,
      config,
      pkgs,
      ...
    }: {
      imports = [
        ./desktop.nix
        ./programs.nix
        ./services.nix
      ];

      options.userConfig = {
        desktop.enable = lib.mkEnableOption "desktop environment configuration";
        nixd.enable = lib.mkEnableOption "nixd LSP";
      };

      config = {
        home = {
          username = "lapine";
          homeDirectory = "/home/lapine";
          stateVersion = "25.11";

          packages = with pkgs;
            [
              curl
              fd
              fzf
              jq
              ldns
              mtr
              nvimpager
              ripgrep
              rsync
              socat
              traceroute
              tree
              whois
            ]
            ++ lib.optionals config.userConfig.desktop.enable [
              bat
              brightnessctl
              duf
              eza
              fastfetch
              gping
              grim
              minisign
              nmap
              playerctl
              rclone
              slurp
              wl-clipboard
              yt-dlp
            ];

          sessionVariables = {
            PAGER = "nvimpager";
            MANPAGER = "nvimpager";
          };
        };

        programs.home-manager.enable = true;

        systemd.user.startServices = "sd-switch";
      };
    };
  };
}
