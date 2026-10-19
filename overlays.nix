{
  modifications = _final: prev: {
    linuxPackages_7_2 = prev.linuxPackages_7_2.extend (_: kernelPackages: {
      v4l2loopback = kernelPackages.v4l2loopback.overrideAttrs (old: {
        # NixOS generates dependency indexes after merging the kernel modules.
        installFlags = (old.installFlags or []) ++ ["DEPMOD=true"];
      });
    });

    discord = prev.discord.override {
      commandLineArgs = "--force-device-scale-factor=1";
    };
  };
}
