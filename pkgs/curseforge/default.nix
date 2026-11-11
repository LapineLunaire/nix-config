{
  appimageTools,
  fetchurl,
  lib,
}: let
  pname = "curseforge";
  # The update workflow sets the version and hash from https://curseforge.overwolf.com/electron/linux/latest-linux.yml.
  inherit (lib.importJSON ./pin.json) version hash;
  src = fetchurl {
    url = "https://curseforge.overwolf.com/electron/linux/CurseForge-${version}.AppImage";
    inherit hash;
  };
  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/curseforge.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/curseforge.desktop --replace-fail 'Exec=AppRun' 'Exec=curseforge'
      cp -r ${contents}/usr/share/icons $out/share
    '';

    meta = {
      description = "CurseForge app for downloading and managing game mods";
      homepage = "https://www.curseforge.com/download/app";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = "curseforge";
    };
  }
