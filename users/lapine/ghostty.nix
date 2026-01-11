{...}: {
  programs.ghostty = {
    enable = true;
    settings = {
      window-decoration = false;
      gtk-titlebar = false;
      window-padding-x = 8;
      window-padding-y = 8;
    };
  };
}
