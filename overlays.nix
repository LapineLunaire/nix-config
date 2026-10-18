{
  modifications = _final: prev: {
    linuxPackages_7_2 = prev.linuxPackages_7_2.extend (_: kernelPackages: {
      v4l2loopback = kernelPackages.v4l2loopback.overrideAttrs (old: {
        # NixOS generates dependency indexes after merging the kernel modules.
        installFlags = (old.installFlags or []) ++ ["DEPMOD=true"];
      });
    });

    davinci-resolve = prev.symlinkJoin {
      inherit (prev.davinci-resolve) name meta;
      paths = [prev.davinci-resolve];
      nativeBuildInputs = [prev.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/davinci-resolve --set QT_QPA_PLATFORM xcb
      '';
    };

    winbox4 =
      if prev.stdenv.hostPlatform.isLinux
      then
        prev.winbox4.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              wrapProgram $out/bin/WinBox --set QT_QPA_PLATFORM xcb
            '';
        })
      else prev.winbox4;

    discord = prev.discord.override {
      commandLineArgs = "--force-device-scale-factor=1";
    };
  };
}
