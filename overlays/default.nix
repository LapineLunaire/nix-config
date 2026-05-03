{...}: {
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    # TestFsType fails in Nix sandbox when build dir is on ZFS (magic 0x2fc12fc1 unrecognized by test)
    prometheus = prev.prometheus.overrideAttrs (oldAttrs: {
      checkFlags = (oldAttrs.checkFlags or []) ++ ["-skip=TestFsType"];
    });

    # these packages' tests invoke ffmpeg which is killed by the Nix sandbox
    kvazaar = prev.kvazaar.overrideAttrs (_: {doCheck = false;});
    chromaprint = prev.chromaprint.overrideAttrs (_: {doCheck = false;});

    ffmpeg-full = prev.ffmpeg-full.override {
      withUnfree = true;
      kvazaar = final.kvazaar;
      chromaprint = final.chromaprint;
    };

    mpv = prev.mpv.override {
      mpv-unwrapped = prev.mpv-unwrapped.override {
        ffmpeg = final.ffmpeg-full;
      };
    };

    yt-dlp = prev.yt-dlp.override {
      ffmpeg-headless = final.ffmpeg-full;
    };

    # protonmail-desktop crashes under native Wayland, so it is forced to use X11 via XWayland.
    protonmail-desktop =
      if prev.stdenv.hostPlatform.isLinux
      then
        prev.protonmail-desktop.overrideAttrs (oldAttrs: {
          postFixup =
            (oldAttrs.postFixup or "")
            + ''
              wrapProgram $out/bin/proton-mail \
                --add-flags "--ozone-platform=x11"
            '';
        })
      else prev.protonmail-desktop;
  };
}
