{pkgs, ...}: {
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Wait for KWin to export the display environment to user services.
  systemd.user.services.kde-baloo = {
    overrideStrategy = "asDropin";
    after = ["plasma-kwin_wayland.service"];
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    elisa
    kate
    konsole
  ];

  programs.kde-pim.enable = false;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
  };
}
