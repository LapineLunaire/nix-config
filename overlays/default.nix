{...}: {
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    # TestFsType fails in Nix sandbox when build dir is on ZFS (magic 0x2fc12fc1 unrecognized by test)
    prometheus = prev.prometheus.overrideAttrs (oldAttrs: {
      checkFlags = (oldAttrs.checkFlags or []) ++ ["-skip=TestFsType"];
    });

    # TestZoneReload and TestView are flaky in upstream coredns 1.14.x
    coredns = prev.coredns.overrideAttrs (oldAttrs: {
      checkFlags = (oldAttrs.checkFlags or []) ++ ["-skip=TestZoneReload|TestView"];
    });

    # "Throws error if filename is not UTF8" fails in the Nix sandbox
    gjs = prev.gjs.overrideAttrs (_: {doCheck = false;});

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
  };
}
