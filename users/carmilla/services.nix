{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.userConfig.desktop.enable {
    services.easyeffects.enable = true;

    systemd.user.services.easyeffects = {
      Unit.Requires = ["pipewire.socket"];
      Unit.After = ["waybar.service"];
      Service.Restart = lib.mkForce "always";
    };

    # oo7 is a modern Secret Service implementation (replaces gnome-keyring).
    # Auto-unlock on login is handled by pam_oo7 (custom package) in the system PAM config.
    systemd.user.services.oo7-daemon = {
      Unit.Description = "Secret service (oo7 implementation)";
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.oo7-server}/libexec/oo7-daemon";
        Restart = "on-failure";
        TimeoutStartSec = "30s";
        TimeoutStopSec = "30s";
        NoNewPrivileges = true;
        PrivateUsers = true;
        ProtectSystem = "full";
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateNetwork = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        MemoryDenyWriteExecute = true;
        ProtectClock = true;
      };
      Install.WantedBy = ["default.target"];
    };

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
            # 5 min inactivity: turn off displays.
            timeout = 300;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            # 10 min inactivity: lock session.
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

    services.ssh-agent.enable = true;
  };
}
