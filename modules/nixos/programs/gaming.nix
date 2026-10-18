{pkgs, ...}: {
  environment.systemPackages = [pkgs.protonplus];

  # Wine and Proton synchronization support.
  boot.kernelModules = ["ntsync"];

  environment.sessionVariables = {
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
  };

  programs.gamemode.enable = true;
  programs.steam.enable = true;
}
