{...}: {
  services.pipewire = {
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
      "99-disable-suspend" = {
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
  };
}
