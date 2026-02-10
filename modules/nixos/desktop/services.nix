{pkgs, ...}: {
  services.speechd.enable = false;

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"node.name" = "~alsa_input.*";}
            {"node.name" = "~alsa_output.*";}
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };
}
