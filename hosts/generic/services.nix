{
  config,
  lib,
  pkgs,
  ...
}: {
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };

  services.earlyoom = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  services.greetd = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  services.pipewire = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
