{lib, ...}: {
  home-manager.users.carmilla = {
    wayland.windowManager.hyprland.settings = {
      monitor = ["DP-2, 2560x1440@165.08, 0x0, 1"];
      general.allow_tearing = true;
      windowrule = lib.mkAfter ["immediate on, match:class .*"];
    };
  };
}
