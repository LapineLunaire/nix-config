{...}: {
  services.displayManager.ly.enable = true;

  # Provides session file for ly and handles Wayland/portals setup
  programs.sway.enable = true;
}
