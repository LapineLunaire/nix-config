{
  modifications = _final: prev: {
    # Adds SCRAM-SHA-256, SCRAM-SHA-512 and channel binding to Dino 0.5.1. Written for 0.5.1 only.
    # Upstream issue: https://github.com/dino/dino/issues/493
    dino = prev.dino.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/dino-scram.patch];
    });

    # Groups T3 Code's Wayland windows under its launcher instead of the hidden URL handler it writes.
    t3code = prev.t3code.overrideAttrs (old: {
      buildCommand =
        old.buildCommand
        + ''
          sed -i 's/^StartupWMClass=.*/StartupWMClass=com.t3tools.T3Code/' "$out/share/applications/t3code.desktop"
        '';
    });
  };
}
