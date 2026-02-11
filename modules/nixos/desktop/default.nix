{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./packages.nix
    ./services.nix
    ./stylix.nix
  ];

  config = {
    home-manager.users.lapine.userConfig.desktop.enable = true;

    boot.kernelModules = ["ntsync"];

    nix.settings = inputs.aagl.nixConfig;

    console.keyMap = "colemak";

    security.rtkit.enable = true;

    environment.sessionVariables = {
      PROTON_ENABLE_WAYLAND = "1";
      PROTON_ENABLE_HDR = "1";
      FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
    };

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    fonts = {
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          autohint = false;
          style = "slight";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
        defaultFonts = {
          monospace = ["JetBrainsMono Nerd Font" "Noto Sans Mono CJK JP"];
          sansSerif = ["Noto Sans" "Noto Sans CJK JP"];
          serif = ["Noto Serif" "Noto Serif CJK JP"];
          emoji = ["Noto Color Emoji"];
        };
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- Reject monochrome Noto Emoji so color variant is always used -->
            <selectfont>
              <rejectfont>
                <pattern>
                  <patelt name="family"><string>Noto Emoji</string></patelt>
                </pattern>
              </rejectfont>
            </selectfont>
            <!-- Append Noto Color Emoji as fallback for all common families -->
            <match target="pattern">
              <test name="family" qual="any"><string>sans-serif</string></test>
              <edit name="family" mode="append" binding="weak">
                <string>Noto Color Emoji</string>
              </edit>
            </match>
            <match target="pattern">
              <test name="family" qual="any"><string>serif</string></test>
              <edit name="family" mode="append" binding="weak">
                <string>Noto Color Emoji</string>
              </edit>
            </match>
            <match target="pattern">
              <test name="family" qual="any"><string>monospace</string></test>
              <edit name="family" mode="append" binding="weak">
                <string>Noto Color Emoji</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };
}
