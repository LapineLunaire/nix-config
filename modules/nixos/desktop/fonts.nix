{
  lib,
  pkgs,
  ...
}: {
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    fontconfig = {
      subpixel.rgba = "rgb";

      # Choose CJK fonts per language below, rather than making one the global default.
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font"];
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        emoji = ["Noto Color Emoji"];
      };

      confPackages = let
        cjkFamilies = {
          monospace = "Noto Sans Mono CJK";
          sans-serif = "Noto Sans CJK";
          serif = "Noto Serif CJK";
        };

        # Language-specific faces first; Traditional Chinese is the fallback.
        tiers =
          lib.mapAttrsToList (lang: face: {
            inherit lang;
            family = generic: "${cjkFamilies.${generic}} ${face}";
          }) {
            ja = "JP";
            ko = "KR";
            "zh-cn" = "SC";
            "zh-hk" = "HK";
            "zh-tw" = "TC";
          }
          ++ [
            {family = generic: "${cjkFamilies.${generic}} TC";}
            # Keep text forms of characters such as © ahead of emoji.
            {family = _: "Noto Color Emoji";}
          ];

        rules =
          lib.concatMapStrings (
            tier:
              lib.concatMapStrings (generic: ''
                <match target="pattern">
                  ${lib.optionalString (tier ? lang) ''<test name="lang" compare="contains"><string>${tier.lang}</string></test>''}
                  <test name="family"><string>${generic}</string></test>
                  <edit name="family" mode="append_last" binding="strong"><string>${tier.family generic}</string></edit>
                </match>
              '') (lib.attrNames cjkFamilies)
          )
          tiers;
      in [
        (pkgs.writeTextDir "etc/fonts/conf.d/60-cjk-emoji.conf" ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
          ${rules}</fontconfig>
        '')
      ];
    };
  };
}
