{...}: {
  # This overlay adds our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This overlay can be used to modify or add custom versions of packages
  modifications = final: prev: {
    ffmpeg = prev.ffmpeg.override {withUnfree = true;};
    ffmpeg-full = prev.ffmpeg-full.override {withUnfree = true;};
    ffmpeg_6 = prev.ffmpeg_6.override {withUnfree = true;};
    ffmpeg_6-full = prev.ffmpeg_6-full.override {withUnfree = true;};
    ffmpeg_7 = prev.ffmpeg_7.override {withUnfree = true;};
    ffmpeg_7-full = prev.ffmpeg_7-full.override {withUnfree = true;};
    ffmpeg_8 = prev.ffmpeg_8.override {withUnfree = true;};
    ffmpeg_8-full = prev.ffmpeg_8-full.override {withUnfree = true;};

    protonmail-desktop = prev.protonmail-desktop.overrideAttrs (oldAttrs: {
      postFixup =
        (oldAttrs.postFixup or "")
        + ''
          wrapProgram $out/bin/proton-mail \
            --add-flags "--enable-features=UseOzonePlatform --ozone-platform=x11"
        '';
    });
  };
}
