{
  pkgs,
  inputs,
  ...
}: {
  home = {
    username = "lapine";
    homeDirectory = "/Users/lapine";
    stateVersion = "26.05";

    packages = [
      inputs.nixd.packages.${pkgs.stdenv.hostPlatform.system}.nixd
    ];
  };

  programs.home-manager.enable = true;
}
