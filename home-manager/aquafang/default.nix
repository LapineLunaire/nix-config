{...}: {
  imports = [
    ../../users/lapine/programs.nix
  ];

  programs.home-manager.enable = true;
  userConfig.programs.nixd.enable = true;

  home = {
    username = "lapine";
    homeDirectory = "/Users/lapine";
    stateVersion = "25.11";
  };
}
