{pkgs, ...}: {
  # greetd with tuigreet - only shows normal users (not nixbld)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  # Provides session file and handles Wayland/portals setup
  programs.sway.enable = true;
}
