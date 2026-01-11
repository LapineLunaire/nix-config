{
  pkgs,
  inputs,
  ...
}: {
  home = {
    username = "lapine";
    homeDirectory = "/Users/lapine";
    stateVersion = "25.11";
    packages = [
      inputs.nixd.packages.${pkgs.system}.nixd
    ];
  };

  programs.home-manager.enable = true;
}
