{
  modifications = _final: prev: {
    # Adds SCRAM-SHA-256, SCRAM-SHA-512 and channel binding to Dino 0.5.1. Written for 0.5.1 only.
    # Upstream issue: https://github.com/dino/dino/issues/493
    dino = prev.dino.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/dino-scram.patch];
    });
  };
}
