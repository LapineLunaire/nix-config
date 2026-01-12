{pkgs, ...}: {
  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };
  programs.gamemode.enable = true;

  # HDR/Wayland support for Steam/Proton
  environment.sessionVariables = {
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
  };
}
