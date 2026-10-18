{...}: let
  # WirePlumber names the RODECaster nodes after the device serial; fixed names let the routing target them.
  # Keep the alsa_ prefix: later rules see the renamed node, and the desktop suspend rule matches that prefix.
  multichannelOutput = "alsa_output.rodecaster_duo.multichannel";
  mainMixInput = "alsa_input.rodecaster_duo.main_mix";
  fiioOutput = "alsa_output.fiio_k11";

  rodecasterNodes = [
    {
      stream = "output";
      index = 0;
      name = "alsa_output.rodecaster_duo.chat";
      description = "Chat";
    }
    {
      stream = "output";
      index = 1;
      name = multichannelOutput;
      description = "Multi-Channel";
      # Hide the raw output from apps; the virtual sinks still target it.
      props."media.class" = "Audio/Sink/Internal";
    }
    {
      stream = "input";
      index = 0;
      name = "alsa_input.rodecaster_duo.chat";
      description = "Chat";
    }
    {
      stream = "input";
      index = 1;
      name = mainMixInput;
      description = "Main Mix";
    }
  ];
in {
  services.pipewire.wireplumber.extraConfig = {
    "50-rodecaster"."monitor.alsa.rules" =
      [
        {
          matches = [
            {
              "device.vendor.id" = "0x19f7";
              "device.product.id" = "0x0079";
            }
          ];
          actions."update-props"."device.profile" = "pro-audio";
        }
      ]
      ++ map (node: {
        matches = [{"node.name" = "~alsa_${node.stream}\\.usb-R__DE_RODECaster_Duo_.*\\.pro-${node.stream}-${toString node.index}$";}];
        actions."update-props" =
          {
            "node.name" = node.name;
            "node.description" = "RODECaster Duo ${node.description}";
            "node.nick" = "RODECaster Duo ${node.description}";
          }
          // node.props or {};
      })
      rodecasterNodes;
    "51-fiio-k11"."monitor.alsa.rules" = [
      {
        matches = [{"device.name" = "alsa_card.usb-FIIO_FiiO_K11-01";}];
        actions."update-props"."device.profile" = "pro-audio";
      }
      {
        matches = [{"node.name" = "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0";}];
        actions."update-props" = {
          "node.name" = fiioOutput;
          # Only the RODECaster main-mix loopback should drive the K11.
          "media.class" = "Audio/Sink/Internal";
        };
      }
    ];
  };

  # Routing adapted from parzival-space/rodecaster-pro-2-virtual-devices-pipewire.
  services.pipewire.extraConfig.pipewire."51-rodecaster-duo"."context.modules" =
    (map (sink: {
        name = "libpipewire-module-loopback";
        args = {
          "node.name" = "virtual_output.rodecaster_duo.${sink.suffix}";
          "node.description" = "RODECaster Duo ${sink.description}";
          "audio.position" = ["FL" "FR"];
          "capture.props"."media.class" = "Audio/Sink";
          "playback.props" = {
            "target.object" = multichannelOutput;
            "stream.dont-remix" = true;
            "audio.position" = sink.channels;
          };
        };
      }) [
        {
          suffix = "main";
          description = "System";
          channels = ["AUX0" "AUX1"];
        }
        {
          suffix = "game";
          description = "Game";
          channels = ["AUX2" "AUX3"];
        }
        {
          suffix = "music";
          description = "Music";
          channels = ["AUX4" "AUX5"];
        }
        {
          suffix = "a";
          description = "Virtual A";
          channels = ["AUX6" "AUX7"];
        }
        {
          suffix = "b";
          description = "Virtual B";
          channels = ["AUX8" "AUX9"];
        }
      ])
    ++ [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.name" = "loopback.input-to-fiio";
          "node.description" = "RODECaster Main Mix to FiiO K11";
          "audio.position" = ["FL" "FR"];
          "capture.props" = {
            "target.object" = mainMixInput;
            "stream.dont-remix" = true;
            "audio.position" = ["AUX0" "AUX1"];
          };
          "playback.props" = {
            "target.object" = fiioOutput;
            "stream.dont-remix" = true;
            "audio.position" = ["AUX0" "AUX1"];
          };
        };
      }
    ];
}
