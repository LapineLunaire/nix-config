{
  appimageTools,
  fetchurl,
  lib,
}: let
  pname = "curseforge";
  version = "1.326.0-42377";
  # Versions and hashes are listed in https://curseforge.overwolf.com/electron/linux/latest-linux.yml.
  src = fetchurl {
    url = "https://curseforge.overwolf.com/electron/linux/CurseForge-${version}.AppImage";
    hash = "sha512-LpFsA2HGqhT6D3Q0/B3W8gWN320TD1eAziTXFp6sTQubrbfa1sUkTzkLyG5/vVzvr+lBHfzicyojl6lPg6ztFA==";
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
