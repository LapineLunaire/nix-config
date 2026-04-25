{pkgs, ...}: {
  # NetworkManager replaces systemd-networkd on desktops. Explicitly disable networkd so both stacks don't run simultaneously.
  networking.networkmanager.enable = true;
  systemd.network.enable = false;
  services.kmscon = {
    enable = true;
    hwRender = true;
    fonts = [
      {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      }
    ];
  };

  services.speechd.enable = false;

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  # UWSM manages the Hyprland session as a set of systemd user units, enabling proper session lifecycle, cgroup tracking, and clean shutdown.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
      user = "greeter";
    };
  };

  virtualisation.waydroid.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Disable WirePlumber's auto-suspend for all ALSA nodes. Without this, devices go idle after inactivity and cause an audible pop or delay on next use.
    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"node.name" = "~alsa_input.*";}
            {"node.name" = "~alsa_output.*";}
          ];
          actions.update-props."session.suspend-timeout-seconds" = 0;
        }
      ];
    };
  };
}
