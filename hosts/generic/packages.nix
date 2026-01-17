{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh.enable = true;

  programs.direnv = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 3";
      dates = "daily";
    };
    flake = "/etc/nixos";
  };

  environment.systemPackages = with pkgs; [
    smartmontools
  ];
}
