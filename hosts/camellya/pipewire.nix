{
  config,
  pkgs,
  ...
}: let
  serial = config.sops.placeholder."rodecaster-duo-serial";
in {
  services.pipewire.wireplumber.extraConfig."50-rodecaster"."monitor.alsa.rules" = [
    {
      matches = [
        {
          "device.vendor.id" = "0x19f7";
          "device.product.id" = "0x0079";
        }
      ];
      actions."update-props"."device.profile" = "pro-audio";
    }
  ];

  # RODECaster Duo virtual input/output devices, from parzival-space/rodecaster-pro-2-virtual-devices-pipewire (rodecaster-duo-1.7.3), with the serial templated in from the rodecaster-duo-serial secret.
  sops.templates."rodecaster-duo.conf".mode = "0444";
  sops.templates."rodecaster-duo.conf".content = ''
    context.modules = [
        # Audio sinks / output devices

        # System (aka. Main)
        {   name = libpipewire-module-loopback
            args = {
                node.name = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.main"
                node.description = "RODECaster Duo System"
                audio.position = [ FL FR ]

                capture.props = { media.class = "Audio/Sink" }

                playback.props = {
                    target.object = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1"
                    stream.dont-remix = true
                    audio.position = [ AUX0 AUX1 ]
                }
            }
        },

        # Game
        {
            name = libpipewire-module-loopback
            args = {
                node.name = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.game"
                node.description = "RODECaster Duo Game"
                audio.position = [ FL FR ]

                capture.props = { media.class = "Audio/Sink" }

                playback.props = {
                    target.object = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1"
                    stream.dont-remix = true
                    audio.position = [ AUX2 AUX3 ]
                }
            }
        },

        # Music
        {
            name = libpipewire-module-loopback
            args = {
                node.name = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.music"
                node.description = "RODECaster Duo Music"
                audio.position = [ FL FR ]

                capture.props = { media.class = "Audio/Sink" }

                playback.props = {
                    target.object = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1"
                    stream.dont-remix = true
                    audio.position = [ AUX4 AUX5 ]
                }
            }
        },

        # Virtual A
        {
            name = libpipewire-module-loopback
            args = {
                node.name = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.a"
                node.description = "RODECaster Duo Virtual A"
                audio.position = [ FL FR ]

                capture.props = { media.class = "Audio/Sink" }

                playback.props = {
                    target.object = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1"
                    stream.dont-remix = true
                    audio.position = [ AUX6 AUX7 ]
                }
            }
        },

        # Virtual B
        {
            name = libpipewire-module-loopback
            args = {
                node.name = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.b"
                node.description = "RODECaster Duo Virtual B"
                audio.position = [ FL FR ]

                capture.props = { media.class = "Audio/Sink" }

                playback.props = {
                    target.object = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1"
                    stream.dont-remix = true
                    audio.position = [ AUX8 AUX9 ]
                }
            }
        },

        # RODECaster Input to FiiO K11
        {
            name = libpipewire-module-loopback
            args = {
                node.name = "loopback.input-to-fiio"
                node.description = "RODECaster Input to FiiO K11"
                audio.position = [ FL FR ]

                capture.props = {
                    target.object = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-1"
                    stream.dont-remix = true
                    audio.position = [ AUX0 AUX1 ]
                }

                playback.props = {
                    target.object = "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0"
                    stream.dont-remix = true
                    audio.position = [ AUX0 AUX1 ]
                }
            }
        }
    ]

    # Assign correct names to physical devices.
    node.rules = [
        # Output
        {
            matches = [
                {
                    node.name = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1"
                }
            ]
            actions = {
                update-props = {
                    node.description = "RODECaster Duo Multi-Channel"
                    node.nick = "RODECaster Duo Multi-Channel"
                }
            }
        },
        {
            matches = [
                {
                    node.name = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-0"
                }
            ]
            actions = {
                update-props = {
                    node.description = "RODECaster Duo Chat"
                    node.nick = "RODECaster Duo Chat"
                }
            }
        },
        # Input
        {
            matches = [
                {
                    node.name = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-0"
                }
            ]
            actions = {
                update-props = {
                    node.description = "RODECaster Duo Chat"
                    node.nick = "RODECaster Duo Chat"
                }
            }
        },
        {
            matches = [
                {
                    node.name = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-1"
                }
            ]
            actions = {
                update-props = {
                    node.description = "RODECaster Duo Input"
                    node.nick = "RODECaster Duo Input"
                }
            }
        },
    ]
  '';

  services.pipewire.configPackages = [
    (pkgs.runCommand "rodecaster-duo-pipewire-config" {} ''
      mkdir -p $out/share/pipewire/pipewire.conf.d
      ln -s ${config.sops.templates."rodecaster-duo.conf".path} $out/share/pipewire/pipewire.conf.d/51-rodecaster-duo.conf
    '')
  ];

  # Force the pro-audio profile for the FiiO K11 USB DAC so it passes through its native 32-bit format for bit-perfect output.
  services.pipewire.wireplumber.extraConfig."51-fiio-k11"."monitor.alsa.rules" = [
    {
      matches = [{"device.name" = "alsa_card.usb-FIIO_FiiO_K11-01";}];
      actions."update-props"."device.profile" = "pro-audio";
    }
  ];
}
