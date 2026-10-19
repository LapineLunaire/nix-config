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

    # Dino 0.5.1 only supports SCRAM-SHA-1. This patch adds SCRAM-SHA-256 until upstream ships it.
    # The patch is written for 0.5.1 and may fail to apply to later versions.
    # Upstream issue: https://github.com/dino/dino/issues/493
    dino = prev.dino.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/dino-scram-sha-256.patch];
    });
  };
}
