{pkgs, ...}: {
  imports = [
    ./nh.nix
  ];

  programs.zsh.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    curl
    fd
    fzf
    grim
    jq
    playerctl
    ripgrep
    rsync
    slurp
    smartmontools
    socat
    tree
    wl-clipboard
  ];
}
