{pkgs, ...}: {
  imports = [
    ./direnv.nix
    ./nh.nix
    ./steam.nix
  ];

  programs.zsh.enable = true;

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
    bat
    brightnessctl
    curl
    eza
    fd
    fzf
    grim
    htop
    lf
    nvimpager
    playerctl
    ripgrep
    rsync
    slurp
    tree
    wl-clipboard

    gruvbox-kvantum
    kdePackages.qtstyleplugin-kvantum
    qt6Packages.qt6ct
  ];
}
