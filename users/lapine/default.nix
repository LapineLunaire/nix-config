{pkgs, ...}: {
  # System user definition
  users.users.lapine = {
    isNormalUser = true;
    description = "Lapine";
    shell = pkgs.zsh;
    # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
    hashedPassword = "$6$h.m1Ftri0Zjsinfs$jKmYsiTrcWzTOCVGSeKA53p/1twd0buX/qxzS08aB6Dgm7PVl9jQTeiZEmb4MIBWrZHEsyLt/ejQsko4b.abf/";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    # FIDO2 hardware key
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU="
    ];
  };

  # Home Manager configuration
  home-manager.users.lapine = {
    imports = [
      ./ghostty.nix
      ./git.nix
      ./rofi.nix
      ./sway.nix
      ./swaync.nix
      ./swaylock.nix
      ./waybar.nix
      ./yazi.nix
      ./zed.nix
      ./zsh.nix
    ];

    home = {
      username = "lapine";
      homeDirectory = "/home/lapine";
      stateVersion = "25.11";
      packages = with pkgs; [
        fastfetch
        firefox
        jq
        legendary-gl
        minisign
        mpv
        nmap
        rclone
        socat
        yt-dlp
      ];
      sessionVariables = {
        PAGER = "nvimpager";
        MANPAGER = "nvimpager";
      };
    };

    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME/desktop";
        documents = "$HOME/documents";
        download = "$HOME/downloads";
        music = "$HOME/music";
        pictures = "$HOME/pictures";
        publicShare = "$HOME/public";
        templates = "$HOME/templates";
        videos = "$HOME/videos";
      };
    };

    services.easyeffects.enable = true;

    # dconf not needed for Sway
    dconf.enable = false;
    programs.home-manager.enable = true;
    # Restart services on config change
    systemd.user.startServices = "sd-switch";
  };
}
