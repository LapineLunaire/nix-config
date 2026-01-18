{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.userConfig.desktop.enable {
    services.ssh-agent.enable = true;

    services.easyeffects = {
      enable = true;
    };

    systemd.user.services.easyeffects = {
      Unit = {
        After = lib.mkForce ["graphical-session.target" "tray.target"];
      };
    };
    services.swayosd.enable = true;

    services.kanshi = {
      enable = true;
      systemdTarget = "sway-session.target";
    };

    services.swayidle = {
      enable = true;
      events = {
        before-sleep = "swaylock -f";
        lock = "swaylock -f";
      };
      timeouts = [
        {
          timeout = 300;
          command = "swaymsg 'output * power off'";
          resumeCommand = "swaymsg 'output * power on'";
        }
        {
          timeout = 600;
          command = "swaylock -f";
        }
      ];
    };

    services.swaync = {
      enable = true;
      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        control-center-layer = "top";
        layer-shell = true;
        cssPriority = "application";
        control-center-margin-top = 8;
        control-center-margin-bottom = 8;
        control-center-margin-right = 8;
        control-center-margin-left = 8;
        notification-2fa-action = true;
        notification-inline-replies = false;
        notification-icon-size = 64;
        notification-body-image-height = 100;
        notification-body-image-width = 200;
        timeout = 5;
        timeout-low = 3;
        timeout-critical = 0;
        fit-to-screen = true;
        control-center-width = 400;
        notification-window-width = 400;
        keyboard-shortcuts = true;
        image-visibility = "when-available";
        transition-time = 200;
        hide-on-clear = false;
        hide-on-action = true;
        script-fail-notify = true;
        widgets = [
          "title"
          "dnd"
          "notifications"
        ];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
          };
          dnd = {
            text = "Do Not Disturb";
          };
        };
      };
    };
  };
}
