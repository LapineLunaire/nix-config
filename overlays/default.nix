{...}: {
  # This overlay adds our custom packages from the 'pkgs' directory.
  additions = final: _prev: import ../pkgs final.pkgs;

  # This overlay can be used to modify or add custom versions of packages.
  modifications = final: prev: {
    # TestFsType fails in Nix sandbox when build dir is on ZFS (magic 0x2fc12fc1 unrecognized by test)
    prometheus = prev.prometheus.overrideAttrs (oldAttrs: {
      checkFlags = (oldAttrs.checkFlags or []) ++ ["-skip=TestFsType"];
    });

    # fish/zsh lack codesignatures in the Nix sandbox on aarch64-darwin, causing the direnv checkPhase to hang silently (nixpkgs #513019)
    direnv =
      if prev.stdenv.hostPlatform.isDarwin
      then prev.direnv.overrideAttrs (_: {doCheck = false;})
      else prev.direnv;

    ffmpeg-full = prev.ffmpeg-full.override {withUnfree = true;};

    mpv = prev.mpv.override {
      mpv-unwrapped = prev.mpv-unwrapped.override {
        ffmpeg = prev.ffmpeg.override {withUnfree = true;};
      };
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
