{pkgs, ...}: {
  imports = [
    ./direnv.nix
    ./nh.nix
    ./obs.nix
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
    # CLI utilities
    bat
    brightnessctl
    curl
    duf
    eza
    fd
    fzf
    gping
    htop
    lf
    nvimpager
    playerctl
    ripgrep
    rsync
    tealdeer
    tree

    # Wayland tools
    grim
    slurp
    wl-clipboard

    # Qt theming
    gruvbox-kvantum
    kdePackages.qtstyleplugin-kvantum
    qt6Packages.qt6ct
  ];
}
