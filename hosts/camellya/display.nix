{lib, ...}: {
  home-manager.users.carmilla = {
    wayland.windowManager.hyprland.settings = {
      monitor = ["DP-2, 2560x1440@165.08, 0x0, 1"];
      # allow_tearing + immediate windowrule enables tearing for all windows, reducing input latency at the cost of potential visual tearing.
      # Equivalent to disabling vsync globally.
      general.allow_tearing = true;
      windowrule = lib.mkAfter ["immediate on, match:class .*"];
    };
  };
}
