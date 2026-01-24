{pkgs, ...}: {
  home-manager.users.lapine = {
    wayland.windowManager.sway.config.output."DP-2" = {
      mode = "2560x1440@165.080Hz";
      allow_tearing = "yes";
    };
  };

  services.pipewire = {
    extraConfig.pipewire."99-mic-processing" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Processed Microphone";
            "media.name" = "Processed Microphone";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_stereo";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.passive" = true;
              "node.target" = "alsa_input.usb-Generic_Blue_Microphones_2246BAH01D78-00.analog-stereo";
            };
            "playback.props" = {
              "media.class" = "Audio/Source";
            };
          };
        }
      ];
    };

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
