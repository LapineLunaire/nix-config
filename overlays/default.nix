{
  modifications = _final: prev: {
    # SSH askpass helpers must execute; /tmp is mounted with noexec.
    zed-editor =
      if prev.stdenv.hostPlatform.isLinux
      then
        prev.symlinkJoin {
          name = "zed-editor-with-runtime-tmp";
          paths = [prev.zed-editor];
          nativeBuildInputs = [prev.makeWrapper];
          postBuild = ''
            wrapProgram "$out/bin/zeditor" \
              --run 'export TMPDIR="''${XDG_RUNTIME_DIR:?}/zed"' \
              --run '${prev.coreutils}/bin/mkdir -p -m 700 "$TMPDIR"'
          '';
          inherit (prev.zed-editor) meta;
        }
      else prev.zed-editor;

    # Adds SCRAM-SHA-256, SCRAM-SHA-512 and channel binding to Dino 0.5.1. Written for 0.5.1 only.
    # Upstream issue: https://github.com/dino/dino/issues/493
    dino = prev.dino.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/dino-scram.patch];
    });

    # Groups T3 Code's Wayland windows under its launcher instead of the hidden URL handler it writes.
    # The launcher path makes that handler start T3 Code instead of bare Electron.
    t3code = prev.t3code.overrideAttrs (old: {
      buildCommand =
        old.buildCommand
        + ''
          sed -i 's/^StartupWMClass=.*/StartupWMClass=com.t3tools.T3Code/' "$out/share/applications/t3code.desktop"
          wrapProgram "$out/bin/t3code-desktop" --set-default T3CODE_DESKTOP_LAUNCHER_PATH "$out/bin/t3code-desktop"
        '';
    });
  };
}
