{pkgs, ...}: {
  programs.zsh.enable = true;

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
