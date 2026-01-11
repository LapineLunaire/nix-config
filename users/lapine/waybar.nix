{...}: {
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "sway-session.target";
    };
    style = ''
      #workspaces button {
        color: @base05;
        background: transparent;
      }
      #workspaces button.focused {
        color: @base0D;
        background: @base02;
        font-weight: bold;
      }
      #workspaces button.urgent {
        color: @base08;
        background: @base01;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 8;

        modules-left = ["sway/workspaces" "sway/mode"];
        modules-center = ["clock"];
        modules-right = ["tray" "network" "cpu" "memory" "temperature"];

        tray = {
          spacing = 8;
        };

        "sway/workspaces" = {
          format = "{name}";
          disable-scroll = true;
        };

        "sway/mode" = {
          format = "{}";
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M:%S}";
          interval = 1;
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format = "CPU {usage}%";
          interval = 2;
        };

        memory = {
          format = "RAM {percentage}%";
          interval = 2;
        };

        temperature = {
          format = "{temperatureC}°C";
          critical-threshold = 80;
        };

        network = {
          format-wifi = "{ipaddr}";
          format-ethernet = "{ipaddr}";
          format-disconnected = "Offline";
          tooltip-format = "{ifname}: {essid}";
        };
      };
    };
  };
}
