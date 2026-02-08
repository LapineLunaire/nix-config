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
    };
  };
}
