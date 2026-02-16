{pkgs, ...}: {
  home = {
    username = "lapine";
    homeDirectory = "/Users/lapine";
    stateVersion = "26.05";

    packages = [
      pkgs.nixd
    ];
  };

  programs.home-manager.enable = true;
}
