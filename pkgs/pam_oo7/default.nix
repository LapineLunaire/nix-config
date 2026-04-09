{
  cargo,
  meson,
  ninja,
  oo7,
  rustPlatform,
  rustc,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "pam_oo7";
  inherit (oo7) version src cargoDeps;

  sourceRoot = "${finalAttrs.src.name}/pam";
  cargoRoot = "../";

  nativeBuildInputs = [
    meson
    ninja
    rustPlatform.cargoSetupHook
    rustc
    cargo
  ];

  meta = {
    inherit
      (oo7.meta)
      homepage
      changelog
      license
      maintainers
      platforms
      ;
    description = "${oo7.meta.description} (PAM module)";
  };
})
