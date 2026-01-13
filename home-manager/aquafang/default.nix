{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../users/lapine/programs.nix
  ];

  userConfig.programs.nixd.enable = true;

  home = {
    username = "lapine";
    homeDirectory = "/Users/lapine";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
