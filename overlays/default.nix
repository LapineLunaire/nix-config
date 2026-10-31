{
  modifications = _final: prev: {
    # Temporary backport of https://github.com/NixOS/nixpkgs/pull/581099.
    discord = prev.discord.override {
      unwrappedDiscord = prev.discord.unwrappedDiscord.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            # Keep the replacement the same length to preserve ASAR offsets.
            grep -qF libopenh264-2.5.1-linux64.7.so $out/opt/Discord/modules/discord_desktop_core/core.asar
            sed -i 's/libopenh264-2\.5\.1-linux64\.7\.so/libopenh264-2.7.0-linux64.8.so/g' \
              $out/opt/Discord/modules/discord_desktop_core/core.asar
          '';
      });
    };

    # Adds SCRAM-SHA-256, SCRAM-SHA-512 and channel binding to Dino 0.5.1. Written for 0.5.1 only.
    # Upstream issue: https://github.com/dino/dino/issues/493
    dino = prev.dino.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/dino-scram.patch];
    });
  };
}
