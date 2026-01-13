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
      ./desktop.nix
      ./programs.nix
      ./shell.nix
    ];

    userConfig.desktop.enable = true;
    userConfig.programs.gui.enable = true;
    userConfig.programs.nixd.enable = true;

    home = {
      username = "lapine";
      homeDirectory = "/home/lapine";
      stateVersion = "25.11";

      packages = with pkgs; [
        bat
        discord
        duf
        eza
        fastfetch
        firefox
        gping
        heroic
        htop
        imv
        ldns
        minisign
        mpv
        mtr
        nmap
        nvimpager
        protonmail-desktop
        protonvpn-gui
        rclone
        tealdeer
        traceroute
        whois
        yt-dlp
      ];

      sessionVariables = {
        PAGER = "nvimpager";
        MANPAGER = "nvimpager";
      };
    };

    programs.home-manager.enable = true;
    programs.swaylock.enable = true;

    services.easyeffects.enable = true;
    services.swayosd.enable = true;
    services.kanshi = {
      enable = true;
      systemdTarget = "sway-session.target";
    };

    # Restart services on config change
    systemd.user.startServices = "sd-switch";
  };
}
