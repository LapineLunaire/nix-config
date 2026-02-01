{...}: {
  # This overlay adds our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This overlay can be used to modify or add custom versions of packages
  modifications = final: prev: {
    protonmail-desktop = prev.protonmail-desktop.overrideAttrs (oldAttrs: {
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/proton-mail \
          --add-flags "--enable-features=UseOzonePlatform --ozone-platform=x11"
      '';
    });
  };
}
