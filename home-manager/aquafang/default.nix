{...}: {
  imports = [
    ../../users/lapine/programs.nix
  ];

  programs.home-manager.enable = true;
  userConfig.nixd.enable = true;

  home = {
    username = "lapine";
    homeDirectory = "/Users/lapine";
    stateVersion = "25.11";
  };
}
