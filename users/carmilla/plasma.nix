# Plasma desktop configuration via plasma-manager, applied on hosts that enable the desktop flag.
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.userConfig.desktop.enable {
    home.packages = [pkgs.bibata-cursors];

    programs.plasma = {
      enable = true;

      workspace = {
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 22;
        };
        iconTheme = "breeze-dark";
        # Reference the persistent repo path directly so the large image isn't copied into the nix store.
        wallpaper = "/persist/nix-config/wallpapers/__camellya_wuthering_waves_drawn_by_lemontea_ekvr5838__1ba4f9536e85b04a5d04733db7eee4e9.png";
      };

      kscreenlocker.appearance.wallpaper = "/persist/nix-config/wallpapers/__camellya_wuthering_waves_drawn_by_bantish__231537f8c01272b8cb8f88e7a518a7a8.jpg";

      input.keyboard.layouts = [
        {
          layout = "us";
          variant = "colemak";
        }
        {
          layout = "us";
        }
      ];

      hotkeys.commands."launch-ghostty" = {
        name = "Launch Ghostty";
        key = "Meta+Alt+K";
        command = "ghostty";
      };

      panels = [
        {
          location = "top";
          height = 24;
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
          height = 40;
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
