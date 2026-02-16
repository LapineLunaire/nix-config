{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.userConfig.desktop.enable {
    services.ssh-agent.enable = true;

    services.easyeffects.enable = true;

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 600;
            on-timeout = "loginctl lock-session";
          }
        ];
      };
    };

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 5;
        };
        background = lib.mkForce [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];
        input-field = lib.mkForce [
          {
            size = "250, 50";
            outline_thickness = 2;
            fade_on_empty = true;
            placeholder_text = "";
            position = "0, -20";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    services.mako = {
      enable = true;
      settings = {
        width = 400;
        margin = "8";
        layer = "overlay";
        max-icon-size = 64;
        default-timeout = 5000;
        anchor = "top-right";
      };
    };
  };
}
