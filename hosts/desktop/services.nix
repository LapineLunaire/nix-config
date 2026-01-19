{pkgs, ...}: {
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

    wireplumber.extraConfig = {
      "51-fiio-k11" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {"device.name" = "alsa_card.usb-FIIO_FiiO_K11-01";}
            ];
            actions = {
              "update-props" = {
                "api.alsa.period-size" = 256;
                "api.alsa.headroom" = 0;
                "audio.format" = "S32LE";
              };
            };
          }
        ];
      };
    };
  };
}
