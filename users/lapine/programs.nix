{pkgs, ...}: {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
      obs-vaapi
      wlrobs
    ];
  };

  programs.ghostty = {
    enable = true;
    settings = {
      window-decoration = false;
      gtk-titlebar = false;
      window-padding-x = 8;
      window-padding-y = 8;
    };
  };

  programs.rofi = {
    enable = true;
    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{name}";
    };
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };
  };

  gtk.iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
}
