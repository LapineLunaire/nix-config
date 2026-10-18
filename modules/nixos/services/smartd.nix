{pkgs, ...}: {
  services.smartd.enable = true;
  environment.systemPackages = [pkgs.smartmontools];
}
