{...}: {
  # This overlay adds our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This overlay can be used to modify or add custom versions of packages
  modifications = final: prev: {
    ffmpeg-full = prev.ffmpeg-full.override {withUnfree = true;};

    mpv = prev.mpv.override {
      mpv-unwrapped = prev.mpv-unwrapped.override {
        ffmpeg = prev.ffmpeg.override {withUnfree = true;};
      };
    };

    protonmail-desktop = prev.protonmail-desktop.overrideAttrs (oldAttrs: {
      postFixup =
        (oldAttrs.postFixup or "")
        + ''
          wrapProgram $out/bin/proton-mail \
            --add-flags "--ozone-platform=x11"
        '';
    });
  };
}
