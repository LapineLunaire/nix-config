{pkgs, ...}: {
  programs.zsh.enable = true;

  programs.neovim = {
    enable = true;
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
    flake = "/persist/nix-config";
  };

  environment.systemPackages = with pkgs; [
    cifs-utils
    ghostty.terminfo
    smartmontools
  ];
}
