{
  config,
  lib,
  pkgs,
  ...
}: let
  mod = "ALT";
in {
  config = lib.mkIf config.userConfig.desktop.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
    };

    gtk.iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      settings = {
        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 2;
          layout = "dwindle";
        };

        decoration = {
          rounding = 0;

          blur = {
            enabled = true;
            size = 6;
            passes = 3;
          };

          active_opacity = 1.0;
          inactive_opacity = 0.95;
        };

        animations = {
          enabled = true;
          bezier = [
            "quick, 0.15, 0, 0.1, 1"
          ];
          animation = [
            "windows, 1, 2, quick, slide"
            "windowsOut, 1, 2, quick, slide"
            "fade, 1, 2, quick"
            "workspaces, 1, 2, quick, slide"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        input = {
          kb_layout = "us";
          kb_variant = "colemak";
          repeat_delay = 300;
          repeat_rate = 50;

          accel_profile = "flat";

          touchpad = {
            tap-to-click = true;
            natural_scroll = true;
            disable_while_typing = true;
          };
        };

        "$mod" = mod;

        # Hyprland defaults translated to Colemak
        # QWERTY → Colemak: e→f r→p p→; j→n s→r m→m (q,c,v unchanged)
        bind = [
          "$mod, q, exec, ghostty"
          "$mod, c, killactive"
          "$mod, m, exit"
          "$mod, f, exec, ghostty -e yazi" # QWERTY E
          "$mod, v, togglefloating"
          "$mod, p, exec, rofi -show drun" # QWERTY R
          "$mod, semicolon, pseudo" # QWERTY P
          "$mod, n, togglesplit" # QWERTY J
          "$mod, Escape, exec, hyprlock"
          "$mod, k, exec, makoctl dismiss"

          # Focus (arrow keys, same as Hyprland default)
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # Workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # Scratchpad
          "$mod, r, togglespecialworkspace, magic" # QWERTY S
          "$mod SHIFT, r, movetoworkspace, special:magic"

          # Mouse scroll workspaces
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # Screenshots
          ", Print, exec, grim - | wl-copy"
          "SHIFT, Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        ];

        # Volume/brightness (repeat-enabled + locked)
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        # Media (locked)
        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        # Mouse binds
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        exec-once = [
          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          (toString (pkgs.writeShellScript "random-wallpaper" ''
            wallpaper="$(${pkgs.findutils}/bin/find ~/pictures/wallpapers -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n 1)"
            if [ -n "$wallpaper" ]; then
              ${pkgs.hyprpaper}/bin/hyprpaper &
              sleep 1
              hyprctl hyprpaper preload "$wallpaper"
              hyprctl hyprpaper wallpaper ",$wallpaper"
            fi
          ''))
        ];

        windowrule = [
          "float on, match:class ^(elysia)$"
          "float on, match:class ^(moe\\.launcher\\.the-honkers-railway-launcher)$"
          "float on, match:class ^(endfield\\.exe)$"
        ];
      };
    };

    programs.rofi = {
      enable = true;
      extraConfig = {
        modi = "drun,run";
        show-icons = true;
        drun-display-format = "{name}";
      };
    };

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
      style = ''
        #workspaces button {
          color: @base05;
          background: transparent;
        }
        #workspaces button.active {
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

          modules-left = ["hyprland/workspaces"];
          modules-center = ["clock"];
          modules-right = ["tray" "network" "cpu" "memory"];

          tray = {
            spacing = 8;
          };

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              "1" = "一";
              "2" = "二";
              "3" = "三";
              "4" = "四";
              "5" = "五";
              "6" = "六";
              "7" = "七";
              "8" = "八";
              "9" = "九";
              "10" = "十";
            };
            disable-scroll = true;
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

          network = {
            format-wifi = "{ipaddr}";
            format-ethernet = "{ipaddr}";
            format-disconnected = "Offline";
            tooltip-format = "{ifname}: {essid}";
          };
        };
      };
    };

    xdg = {
      enable = true;

      portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk];
        config.common.default = ["hyprland" "gtk"];
      };

      configFile."hypr/hyprpaper.conf".text = ''
        splash = false
      '';

      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME/desktop";
        documents = "$HOME/documents";
        download = "$HOME/downloads";
        music = "$HOME/music";
        pictures = "$HOME/pictures";
        publicShare = "$HOME/public";
        templates = "$HOME/templates";
        videos = "$HOME/videos";
      };
    };
  };
}
