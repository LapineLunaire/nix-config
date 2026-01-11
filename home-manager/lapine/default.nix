{pkgs, ...}: {
  imports = [
    ./git.nix
    ./sway.nix
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

  # dconf not needed for Sway
  dconf.enable = false;
  programs.home-manager.enable = true;
  # Restart services on config change
  systemd.user.startServices = "sd-switch";
}
