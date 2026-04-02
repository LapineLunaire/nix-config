{
  alsa-lib,
  clang,
  fetchFromGitea,
  fetchFromGitHub,
  fetchgit,
  ffmpeg_8,
  fontconfig,
  gn,
  lib,
  libGL,
  libglvnd,
  libxkbcommon,
  ninja,
  openssl,
  pkg-config,
  python3,
  runCommand,
  rustPlatform,
  wayland,
}: let
  skia-src = fetchFromGitHub {
    owner = "rust-skia";
    repo = "skia";
    rev = "2cb22021483e8f6646f94cea918a61a4a9bd5192";
    hash = "sha256-35dQPlvE5mvFv+bvdKG1r9tme8Ba5hnuepVbUp1J9S4=";
    fetchSubmodules = true;
  };

  # third_party/externals — from Skia's DEPS at the above rev
  dep-brotli = fetchFromGitHub {
    owner = "google";
    repo = "brotli";
    rev = "6d03dfbedda1615c4cba1211f8d81735575209c8";
    hash = "sha256-WSRBRwb2VVbjsNHkKrpTVnPhSiQGkUTc5ISXQKrl5UE=";
  };

  dep-expat = fetchFromGitHub {
    owner = "libexpat";
    repo = "libexpat";
    rev = "8e49998f003d693213b538ef765814c7d21abada";
    hash = "sha256-zP2kiB4nyLi0/I8OsRhxKG0qRGPe2ALLQ+HHfqlBJ6Y=";
  };

  dep-freetype = fetchgit {
    url = "https://chromium.googlesource.com/chromium/src/third_party/freetype2.git";
    rev = "702e4a1d32e4b911e85cc7df84b3ba395c28dab3";
    hash = "sha256-fcppM3ZVegHF033H+vVOtvtdrnCmkd1QU8B9qTYv4LU=";
  };

  dep-harfbuzz = fetchFromGitHub {
    owner = "harfbuzz";
    repo = "harfbuzz";
    rev = "08b52ae2e44931eef163dbad71697f911fadc323";
    hash = "sha256-sP9FQLUEgTZFlvfYqSZnzZqBMxVotzD0FKKsu3/OdUw=";
  };

  dep-icu = fetchgit {
    url = "https://chromium.googlesource.com/chromium/deps/icu.git";
    rev = "364118a1d9da24bb5b770ac3d762ac144d6da5a4";
    hash = "sha256-frsmwYMiFixEULsE91x5+p98DvkyC0s0fNupqjoRnvg=";
  };

  dep-libjpeg-turbo = fetchgit {
    url = "https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git";
    rev = "e14cbfaa85529d47f9f55b0f104a579c1061f9ad";
    hash = "sha256-Ig+tmprZDvlf/M72/DTar2pbxat9ZElgSqdXdoM0lPs=";
  };

  dep-libpng = fetchgit {
    url = "https://skia.googlesource.com/third_party/libpng.git";
    rev = "ed217e3e601d8e462f7fd1e04bed43ac42212429";
    hash = "sha256-Mo1M8TuVaoSIb7Hy2u6zgjZ1DKgpmgNmGRP6dGg/aTs=";
  };

  dep-libwebp = fetchgit {
    url = "https://chromium.googlesource.com/webm/libwebp.git";
    rev = "845d5476a866141ba35ac133f856fa62f0b7445f";
    hash = "sha256-lH5wpzaCCPCfW2rHevJ7MQ6WpTYkh2LljLvD1nq36To=";
  };

  dep-spirv-cross = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
    rev = "b8fcf307f1f347089e3c46eb4451d27f32ebc8d3";
    hash = "sha256-H43M9DXfEuyKuvo6rjb5k0KEbYOSFodbPJh8ZKY4PQg=";
  };

  dep-vulkanmemoryallocator = fetchFromGitHub {
    owner = "GPUOpen-LibrariesAndSDKs";
    repo = "VulkanMemoryAllocator";
    rev = "a6bfc237255a6bac1513f7c1ebde6d8aed6b5191";
    hash = "sha256-urUebQaPTgCECmm4Espri1HqYGy0ueAqTBu/VSiX/8I=";
  };

  dep-wuffs = fetchFromGitHub {
    owner = "google";
    repo = "wuffs-mirror-release-c";
    rev = "e3f919ccfe3ef542cfc983a82146070258fb57f8";
    hash = "sha256-373d2F/STcgCHEq+PO+SCHrKVOo6uO1rqqwRN5eeBCw=";
  };

  dep-zlib = fetchgit {
    url = "https://chromium.googlesource.com/chromium/src/third_party/zlib";
    rev = "646b7f569718921d7d4b5b8e22572ff6c76f2596";
    hash = "sha256-jNj6SuTZ5/a7crtYhxW3Q/TlfRMNMfYIVxDlr7bYdzQ=";
  };

  skia-src-with-deps = runCommand "skia-with-deps" {} ''
    cp -r ${skia-src} $out
    chmod -R u+w $out

    mkdir -p $out/third_party/externals
    cp -r ${dep-brotli}                $out/third_party/externals/brotli
    cp -r ${dep-expat}                 $out/third_party/externals/expat
    cp -r ${dep-freetype}              $out/third_party/externals/freetype
    cp -r ${dep-harfbuzz}              $out/third_party/externals/harfbuzz
    cp -r ${dep-icu}                   $out/third_party/externals/icu
    cp -r ${dep-libjpeg-turbo}         $out/third_party/externals/libjpeg-turbo
    cp -r ${dep-libpng}                $out/third_party/externals/libpng
    cp -r ${dep-libwebp}               $out/third_party/externals/libwebp
    cp -r ${dep-spirv-cross}           $out/third_party/externals/spirv-cross
    cp -r ${dep-vulkanmemoryallocator} $out/third_party/externals/vulkanmemoryallocator
    cp -r ${dep-zlib}                  $out/third_party/externals/zlib

    mkdir -p $out/third_party/externals/wuffs/release/c
    cp ${dep-wuffs}/release/c/wuffs-v0.3.c $out/third_party/externals/wuffs/release/c/wuffs-v0.3.c
  '';
in
  rustPlatform.buildRustPackage {
    pname = "elysia";
    version = "0.1.0-unstable-2026-01-29";

    src = fetchFromGitea {
      domain = "dawn.wine";
      owner = "elysia";
      repo = "elysia";
      rev = "16bc8e9b2daeeaa3922b54aa117372af9242df3b";
      hash = "sha256-b5A7MdPBjm2UTHN2ci/OD8y9WkYe8j+4KZ4CIeealrw=";
    };

    cargoHash = "sha256-lYg6dRPlIwsEYql9bDdrF29fAvr+8vYLueOxp98gLsc=";

    nativeBuildInputs = [
      pkg-config
      clang
      rustPlatform.bindgenHook
      python3
    ];

    buildInputs = [
      openssl
      ffmpeg_8
      alsa-lib
      libGL
      libglvnd
      wayland
      libxkbcommon
      fontconfig
    ];

    # rust-skia builds Skia from source using GN + Ninja.
    # gn/ninja are passed via env vars rather than nativeBuildInputs to avoid their setup hooks interfering with the cargo build phase.
    SKIA_SOURCE_DIR = skia-src-with-deps;
    SKIA_NINJA_COMMAND = "${ninja}/bin/ninja";
    SKIA_GN_COMMAND = "${gn}/bin/gn";
    CC = "${clang}/bin/clang";
    CXX = "${clang}/bin/clang++";
    CLANGCC = "${clang}/bin/clang";
    CLANGCXX = "${clang}/bin/clang++";

    # skia-bindings 0.87.0 blocklists "std::_Rb_tree.*" for GCC/LLVM9 C++17, but GCC 15 renamed those internals to __rb_tree_node_base.
    # The missing pattern causes std__Rb_tree_color to be referenced but never defined in the generated bindings.
    # Patch the vendored crate to add the new names. This was fixed upstream in a later skia-bindings release.
    preBuild = ''
      skia_bindgen=$(find /build -name "skia_bindgen.rs" -path "*/skia-bindings*" | head -1)
      substituteInPlace "$skia_bindgen" \
        --replace-fail '"std::_Rb_tree.*",' '"std::_Rb_tree.*", "std::__rb_tree.*", "std::_rb_tree.*",'
    '';

    cargoBuildFlags = ["--bin" "elysia"];

    doCheck = false;

    postInstall = ''
      install -Dm644 assets/elysia.desktop $out/share/applications/elysia.desktop
      substituteInPlace $out/share/applications/elysia.desktop \
        --replace-fail '/usr/bin/elysia' 'elysia'
      install -Dm644 assets/elysia.png -t $out/share/pixmaps
    '';

    meta = with lib; {
      description = "Launcher for anime games on Linux using Wine and Proton";
      homepage = "https://dawn.wine/elysia/elysia";
      license = licenses.gpl3Plus;
      mainProgram = "elysia";
      platforms = platforms.linux;
      maintainers = [];
    };
  }
