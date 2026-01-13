{
  config,
  lib,
  pkgs,
  ...
}: {
  # Display manager
  services.greetd = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  # Audio
  security.rtkit.enable = lib.mkIf config.hostConfig.desktop.enable true;
  services.pipewire = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # System services
  # dbus-broker is faster and more secure than dbus-daemon
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

  # Time synchronization
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };

  # Memory management
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
