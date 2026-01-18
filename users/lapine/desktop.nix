{
  config,
  lib,
  pkgs,
  ...
}: let
  mod = "Mod1";
  ws1 = "1:一";
  ws2 = "2:二";
  ws3 = "3:三";
  ws4 = "4:四";
  ws5 = "5:五";
  ws6 = "6:六";
  ws7 = "7:七";
  ws8 = "8:八";
  ws9 = "9:九";
  ws10 = "10:十";
in {
  config = lib.mkIf config.userConfig.desktop.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
      WLR_RENDERER = "vulkan";
    };

    gtk.iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraConfig = "include /etc/sway/config.d/*";

      config = {
        modifier = mod;
        terminal = "ghostty";
        menu = "rofi -show drun";

        output."*" = {
          render_bit_depth = "10";
        };

        gaps = {
          inner = 8;
          outer = 4;
        };

        bars = [];

        input = {
          "type:keyboard" = {
            xkb_layout = "us";
            xkb_variant = "colemak";
            repeat_delay = "300";
            repeat_rate = "50";
          };
          "type:pointer" = {
            accel_profile = "flat";
          };
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "enabled";
          };
        };

        startup = [
          {command = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";}
          {command = "swaymsg workspace ${ws1}";}
          {
            command = ''${pkgs.swaybg}/bin/swaybg -i "$(${pkgs.findutils}/bin/find ~/pictures/wallpapers -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n 1)" -m fill'';
            always = true;
          }
        ];

        keybindings = {
          "${mod}+h" = "focus left";
          "${mod}+n" = "focus down";
          "${mod}+e" = "focus up";
          "${mod}+i" = "focus right";
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+n" = "move down";
          "${mod}+Shift+e" = "move up";
          "${mod}+Shift+i" = "move right";

          "${mod}+b" = "splith";
          "${mod}+v" = "splitv";
          "${mod}+r" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+f" = "layout toggle split";
          "${mod}+t" = "fullscreen toggle";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
          "${mod}+a" = "focus parent";

          "${mod}+Return" = "exec ghostty";
          "${mod}+s" = "exec rofi -show drun";
          "${mod}+k" = "exec swaync-client -t";
          "${mod}+Escape" = "exec swaylock -f";
          "${mod}+Shift+q" = "kill";

          "Print" = "exec grim - | wl-copy";
          "Shift+Print" = "exec grim -g \"$(slurp)\" - | wl-copy";

          "${mod}+1" = "workspace ${ws1}";
          "${mod}+2" = "workspace ${ws2}";
          "${mod}+3" = "workspace ${ws3}";
          "${mod}+4" = "workspace ${ws4}";
          "${mod}+5" = "workspace ${ws5}";
          "${mod}+6" = "workspace ${ws6}";
          "${mod}+7" = "workspace ${ws7}";
          "${mod}+8" = "workspace ${ws8}";
          "${mod}+9" = "workspace ${ws9}";
          "${mod}+0" = "workspace ${ws10}";
          "${mod}+Shift+1" = "move container to workspace ${ws1}";
          "${mod}+Shift+2" = "move container to workspace ${ws2}";
          "${mod}+Shift+3" = "move container to workspace ${ws3}";
          "${mod}+Shift+4" = "move container to workspace ${ws4}";
          "${mod}+Shift+5" = "move container to workspace ${ws5}";
          "${mod}+Shift+6" = "move container to workspace ${ws6}";
          "${mod}+Shift+7" = "move container to workspace ${ws7}";
          "${mod}+Shift+8" = "move container to workspace ${ws8}";
          "${mod}+Shift+9" = "move container to workspace ${ws9}";
          "${mod}+Shift+0" = "move container to workspace ${ws10}";

          "${mod}+Shift+minus" = "move scratchpad";
          "${mod}+minus" = "scratchpad show";
          "${mod}+p" = "mode resize";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+f" = "exec swaymsg exit";

          "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
          "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
          "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
          "XF86AudioMicMute" = "exec swayosd-client --input-volume mute-toggle";
          "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
          "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPrev" = "exec playerctl previous";
        };

        modes = {
          resize = {
            "h" = "resize shrink width 10 px";
            "n" = "resize grow height 10 px";
            "e" = "resize shrink height 10 px";
            "i" = "resize grow width 10 px";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };

        window = {
          border = 2;
          titlebar = false;
        };

        floating = {
          border = 2;
          titlebar = false;
        };
      };
    };

    xdg = {
      enable = true;
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
      portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];
        config.common.default = ["wlr" "gtk"];
      };
    };
  };
}
