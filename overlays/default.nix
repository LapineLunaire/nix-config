{
  modifications = _final: prev: {
    linuxPackages_7_3 = prev.linuxPackages_7_3.extend (_: kernelPackages: {
      v4l2loopback = kernelPackages.v4l2loopback.overrideAttrs (old: {
        # NixOS generates dependency indexes after merging the kernel modules.
        installFlags = (old.installFlags or []) ++ ["DEPMOD=true"];
      });
    });

    discord = prev.discord.override {
      commandLineArgs = "--force-device-scale-factor=1";
    };

    # Adds SCRAM-SHA-256, SCRAM-SHA-512 and channel binding to Dino 0.5.1. Written for 0.5.1 only.
    # Upstream issue: https://github.com/dino/dino/issues/493
    dino = prev.dino.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/dino-scram.patch];
    });
  };
}
