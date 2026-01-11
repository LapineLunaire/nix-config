{
  config,
  pkgs,
  ...
}: let
  # Alt key - Mod4 (Super) conflicts with some apps
  mod = "Mod1";

  # Gruvbox Dark palette (dark0_hard overridden to pure black for OLED)
  dark0_hard = "#000000"; # original: #1d2021
  dark0 = "#282828";
  dark1 = "#3c3836";
  dark2 = "#504945";
  dark3 = "#665c54";
  dark4 = "#7c6f64";
  gray = "#928374";
  light0 = "#fbf1c7";
  light1 = "#ebdbb2";
  light2 = "#d5c4a1";
  light3 = "#bdae93";
  light4 = "#a89984";

  bright_red = "#fb4934";
  bright_green = "#b8bb26";
  bright_yellow = "#fabd2f";
  bright_blue = "#83a598";
  bright_purple = "#d3869b";
  bright_aqua = "#8ec07c";
  bright_orange = "#fe8019";

  neutral_red = "#cc241d";
  neutral_green = "#98971a";
  neutral_yellow = "#d79921";
  neutral_blue = "#458588";
  neutral_purple = "#b16286";
  neutral_aqua = "#689d6a";
  neutral_orange = "#d65d0e";

  transparent = "#00000000";
  semiTransparent = "#000000aa";
  barBg = "#00000066";

  # Workspace names use Chinese numerals (numbers for ordering, stripped in bar)
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
  home = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      XDG_CURRENT_DESKTOP = "sway";
    };
    pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = mod;
      terminal = "ghostty";
      menu = "rofi -show drun";

      fonts = {
        names = ["JetBrainsMono Nerd Font"];
        size = 10.0;
      };

      colors = {
        focused = {
          border = "${bright_blue}cc";
          background = semiTransparent;
          text = light1;
          indicator = bright_aqua;
          childBorder = "${bright_blue}cc";
        };
        focusedInactive = {
          border = "${dark2}88";
          background = semiTransparent;
          text = light2;
          indicator = transparent;
          childBorder = "${dark2}88";
        };
        unfocused = {
          border = transparent;
          background = semiTransparent;
          text = light3;
          indicator = transparent;
          childBorder = transparent;
        };
        urgent = {
          border = "${bright_red}cc";
          background = semiTransparent;
          text = light1;
          indicator = bright_red;
          childBorder = "${bright_red}cc";
        };
        placeholder = {
          border = transparent;
          background = semiTransparent;
          text = light3;
          indicator = transparent;
          childBorder = transparent;
        };
        background = dark0_hard;
      };

      gaps = {
        inner = 8;
        outer = 4;
      };

      bars = [
        {
          position = "top";
          trayOutput = "*";
          extraConfig = "strip_workspace_numbers yes";
          statusCommand = "while date +'%Y-%m-%d %H:%M:%S'; do sleep 1; done";
          fonts = {
            names = ["JetBrainsMono Nerd Font"];
            size = 10.0;
          };
          colors = {
            background = barBg;
            statusline = light2;
            separator = "${dark3}88";
            focusedWorkspace = {
              border = transparent;
              background = "${bright_blue}44";
              text = light1;
            };
            activeWorkspace = {
              border = transparent;
              background = "${dark2}44";
              text = light2;
            };
            inactiveWorkspace = {
              border = transparent;
              background = transparent;
              text = light3;
            };
            urgentWorkspace = {
              border = transparent;
              background = "${bright_red}44";
              text = light1;
            };
            bindingMode = {
              border = transparent;
              background = "${bright_orange}44";
              text = light0;
            };
          };
        }
      ];

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

      output = {
        "*" = {
          bg = "${dark0_hard} solid_color";
        };
      };

      startup = [
        {command = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";}
        {command = "swaymsg workspace ${ws1}";}
      ];

      # Keybindings use Colemak home row (h/n/e/i) for navigation
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
        "${mod}+Escape" = "exec swaylock -f -c 000000";
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

        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
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

  # 5min screen off, 10min lock
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "swaylock -f -c 000000";
      lock = "swaylock -f -c 000000";
    };
    timeouts = [
      {
        timeout = 300;
        command = "swaymsg 'output * power off'";
        resumeCommand = "swaymsg 'output * power on'";
      }
      {
        timeout = 600;
        command = "swaylock -f -c 000000";
      }
    ];
  };

  services.kanshi = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  services.mako = {
    enable = true;
    settings = {
      background-color = semiTransparent;
      text-color = light1;
      border-color = "${bright_blue}88";
      border-radius = 8;
      border-size = 2;
      default-timeout = 5000;
      font = "JetBrainsMono Nerd Font 10";
      padding = "12";
      margin = "8";
      "[urgency=low]".border-color = "${bright_aqua}88";
      "[urgency=normal]".border-color = "${bright_blue}88";
      "[urgency=high]" = {
        border-color = "${bright_red}cc";
        default-timeout = 0;
      };
    };
  };

  programs.rofi = {
    enable = true;
    font = "JetBrainsMono Nerd Font 11";
    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{name}";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral light1;
      };
      window = {
        background-color = mkLiteral dark0_hard;
        border = mkLiteral "2px";
        border-color = mkLiteral bright_blue;
        border-radius = mkLiteral "8px";
        padding = mkLiteral "16px";
        width = mkLiteral "480px";
      };
      inputbar = {
        background-color = mkLiteral dark1;
        border-radius = mkLiteral "4px";
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "8px";
        children = mkLiteral "[entry]";
      };
      entry = {
        placeholder = "Search...";
        placeholder-color = mkLiteral light3;
      };
      listview = {
        margin = mkLiteral "12px 0 0 0";
        lines = 8;
      };
      element = {
        padding = mkLiteral "8px 12px";
        border-radius = mkLiteral "4px";
        spacing = mkLiteral "8px";
      };
      "element selected" = {
        background-color = mkLiteral dark2;
        text-color = mkLiteral bright_blue;
      };
      element-icon = {
        size = mkLiteral "24px";
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Gruvbox-Dark-BL";
      package = pkgs.gruvbox-gtk-theme;
    };
    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
  };

  # Qt theming via Kvantum (qt6ct selects kvantum, kvantum uses gruvbox)
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile = {
    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=gruvbox-kvantum
    '';
    "Kvantum/gruvbox-kvantum".source = "${pkgs.gruvbox-kvantum}/share/Kvantum/gruvbox-kvantum";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];
    config.common.default = ["wlr" "gtk"];
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "000000";
      font = "JetBrainsMono Nerd Font";
      font-size = 24;
      indicator-radius = 100;
      indicator-thickness = 8;
      ring-color = dark2;
      inside-color = dark1;
      key-hl-color = bright_green;
      text-color = light1;
      ring-caps-lock-color = bright_yellow;
      bs-hl-color = bright_red;
      ring-ver-color = bright_blue;
      ring-wrong-color = bright_red;
    };
  };

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      background = dark0_hard;
      foreground = light1;
      cursor-color = light2;
      selection-background = dark2;
      selection-foreground = light1;
      palette = [
        "0=${dark0_hard}"
        "1=${neutral_red}"
        "2=${neutral_green}"
        "3=${neutral_yellow}"
        "4=${neutral_blue}"
        "5=${neutral_purple}"
        "6=${neutral_aqua}"
        "7=${light2}"
        "8=${gray}"
        "9=${bright_red}"
        "10=${bright_green}"
        "11=${bright_yellow}"
        "12=${bright_blue}"
        "13=${bright_purple}"
        "14=${bright_aqua}"
        "15=${light0}"
      ];
      window-decoration = false;
      gtk-titlebar = false;
      window-padding-x = 8;
      window-padding-y = 8;
    };
  };
}
