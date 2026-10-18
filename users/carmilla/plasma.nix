{
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home.packages = [pkgs.bibata-cursors];

    programs.plasma = let
      wallpapers = ./wallpapers;
      interfaceFont = {
        family = "Noto Sans";
        pointSize = 11;
      };
    in {
      enable = true;

      fonts = {
        general = interfaceFont;
        menu = interfaceFont;
        toolbar = interfaceFont;
        windowTitle = interfaceFont;
        small = interfaceFont // {pointSize = 9;};
        fixedWidth = {
          family = "JetBrainsMono Nerd Font";
          pointSize = 11;
        };
      };

      configFile."kdeglobals".General = {
        TerminalApplication = "ghostty";
        TerminalService = "com.mitchellh.ghostty.desktop";
      };

      workspace = {
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 22;
        };
        iconTheme = "breeze-dark";
        wallpaper = "${wallpapers}/__camellya_wuthering_waves_drawn_by_lemontea_ekvr5838__1ba4f9536e85b04a5d04733db7eee4e9.png";
      };

      kscreenlocker = {
        autoLock = true;
        timeout = 5;
        lockOnResume = true;
        passwordRequired = true;
        passwordRequiredDelay = 0;
        appearance.wallpaper = "${wallpapers}/__camellya_wuthering_waves_drawn_by_bantish__231537f8c01272b8cb8f88e7a518a7a8.jpg";
      };

      input.keyboard = {
        layouts = [
          {
            layout = "us";
            variant = "colemak";
          }
          {
            layout = "us";
          }
        ];
        options = ["grp:win_space_toggle"];
        switchingPolicy = "global";
      };

      hotkeys.commands."launch-ghostty" = {
        name = "Launch Ghostty";
        key = "Meta+Alt+K";
        command = "ghostty";
      };

      panels = [
        {
          location = "top";
          height = 30;
          floating = false;
          opacity = "translucent";
          widgets = [
            {
              kicker.icon = "application-menu-symbolic";
            }
            "org.kde.plasma.appmenu"
            "org.kde.plasma.panelspacer"
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.systemtray"
            {
              digitalClock = {
                calendar = {
                  firstDayOfWeek = "monday";
                  showWeekNumbers = true;
                };
                time.format = "24h";
                date.format = "isoDate";
              };
            }
          ];
        }
        {
          location = "bottom";
          height = 44;
          floating = true;
          lengthMode = "fit";
          hiding = "dodgewindows";
          opacity = "translucent";
          widgets = [
            {
              iconTasks.launchers = [
                "applications:systemsettings.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
                "applications:com.mitchellh.ghostty.desktop"
                "applications:dev.zed.Zed.desktop"
              ];
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.trash"
          ];
        }
      ];
    };
  };
}
