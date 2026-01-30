{
  buildFHSEnv,
  callPackage,
}: let
  elysia-unwrapped = callPackage ./package.nix {};
in
  buildFHSEnv {
    name = "elysia";

    targetPkgs = pkgs:
      with pkgs; [
        elysia-unwrapped

        # Required by UMU launcher and Wine/Proton scripts
        bash
        coreutils
        which
        perl
        python3

        # Graphics
        libGL
        vulkan-loader

        # Audio
        libpulseaudio
        alsa-lib

        # Display
        wayland
        libxkbcommon
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi

        # Required by Rust/Skia binaries
        glibc
        gcc-unwrapped
        zlib

        # Prevents dlopen errors when games request it
        gamemode
      ];

    runScript = "elysia";

    # Copy desktop file and icon from the wrapped package
    extraInstallCommands = ''
      mkdir -p $out/share/applications
      mkdir -p $out/share/pixmaps
      cp -r ${elysia-unwrapped}/share/applications/* $out/share/applications/
      cp -r ${elysia-unwrapped}/share/pixmaps/* $out/share/pixmaps/
    '';

    meta = elysia-unwrapped.meta;
  }
