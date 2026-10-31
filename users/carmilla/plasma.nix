{
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home.packages = [pkgs.bibata-cursors];

    programs.brave-origin = {
      nativeMessagingHosts = [pkgs.kdePackages.plasma-browser-integration];
      extensions = [
        {id = "cimiefiiaegbelhefglklhhakcgmhkai";} # Plasma Integration
      ];
    };

    programs.firefox = {
      nativeMessagingHosts = [pkgs.kdePackages.plasma-browser-integration];
      policies.ExtensionSettings."plasma-browser-integration@kde.org" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/plasma-integration/latest.xpi";
      };
    };

    programs.plasma = let
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
      };

      kscreenlocker = {
        autoLock = true;
        timeout = 5;
        lockOnResume = true;
        passwordRequired = true;
        passwordRequiredDelay = 0;
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
              iconTasks.appearance.indicateAudioStreams = false;
              iconTasks.launchers = [
                "applications:firefox.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:com.mitchellh.ghostty.desktop"
                "applications:dev.zed.Zed.desktop"
                "applications:t3code.desktop"
                "applications:discord.desktop"
                "applications:im.dino.Dino.desktop"
                "applications:Fluffychat.desktop"
                "applications:proton-mail.desktop"
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
