{...}: {
  home-manager.users.lapine = {
    wayland.windowManager.sway.config.output."DP-2" = {
      mode = "2560x1440@165.080Hz";
      allow_tearing = "yes";
    };
  };
}
