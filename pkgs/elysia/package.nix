{
  lib,
  fetchFromGitea,
  fetchurl,
  rustPlatform,
  pkg-config,
  openssl,
  ffmpeg_8,
  clang,
  llvmPackages,
  python3,
  alsa-lib,
  libGL,
  libglvnd,
  wayland,
  libxkbcommon,
  freetype,
  fontconfig,
}:
rustPlatform.buildRustPackage rec {
  pname = "elysia";
  version = "0.1.0-unstable-2026-01-29";

  src = fetchFromGitea {
    domain = "dawn.wine";
    owner = "elysia";
    repo = "elysia";
    rev = "dev";
    hash = "sha256-b5A7MdPBjm2UTHN2ci/OD8y9WkYe8j+4KZ4CIeealrw=";
  };

  cargoHash = "sha256-lYg6dRPlIwsEYql9bDdrF29fAvr+8vYLueOxp98gLsc=";

  # Pre-built Skia binaries to avoid building from source
  skiaBinaries = fetchurl {
    url = "https://github.com/rust-skia/skia-binaries/releases/download/0.87.0/skia-binaries-e551f334ad5cbdf43abf-x86_64-unknown-linux-gnu-egl-gl-pdf-svg-textlayout-wayland-x11.tar.gz";
    hash = "sha256-m6Zb7mTlt+c3OgX+Sge+upTl8nXfBQhfFCuzkvFmhJg=";
  };

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
    freetype
    fontconfig
  ];

  # Provide pre-built Skia binaries to the build
  preBuild = ''
    export SKIA_BINARIES_URL="file://${skiaBinaries}"
  '';

  # Required for building with clang
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  # Use clang for compilation
  CC = "${clang}/bin/clang";
  CXX = "${clang}/bin/clang++";

  # Build only the main elysia binary
  cargoBuildFlags = ["--bin" "elysia"];

  doCheck = false;

  postInstall = ''
    # Install desktop file and patch the Exec path
    install -Dm644 assets/elysia.desktop $out/share/applications/elysia.desktop
    substituteInPlace $out/share/applications/elysia.desktop \
      --replace-fail '/usr/bin/elysia' 'elysia'

    # Install icon
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
