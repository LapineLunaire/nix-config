{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    smartmontools
  ];

  services.smartd.enable = true;
}
