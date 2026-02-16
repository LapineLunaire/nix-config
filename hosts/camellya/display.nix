{...}: {
  home-manager.users.lapine = {
    wayland.windowManager.hyprland.settings = {
      monitor = ["DP-2, 2560x1440@165.08, 0x0, 1"];
      general.allow_tearing = true;
      windowrule = ["immediate on, match:class .*"];
    };
  };
}
