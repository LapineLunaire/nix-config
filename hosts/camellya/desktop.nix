{...}: {
  programs.sway = {
    enable = true;
    extraPackages = [];
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };
}
