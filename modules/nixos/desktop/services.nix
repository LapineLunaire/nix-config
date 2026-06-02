{pkgs, ...}: {
  # NetworkManager replaces systemd-networkd on desktops. Explicitly disable networkd so both stacks don't run simultaneously.
  networking.networkmanager.enable = true;
  systemd.network.enable = false;
  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];
  services.kmscon = {
    enable = true;
    config.hwaccel = true;
    config.font-name = "JetBrainsMono Nerd Font";
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us,us";
    variant = "colemak,";
    options = "grp:win_space_toggle";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
    konsole
  ];

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
