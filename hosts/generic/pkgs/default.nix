{pkgs, ...}: {
  imports = [
    ./aagl.nix
    ./direnv.nix
    ./neovim.nix
    ./nh.nix
    ./obs.nix
    ./steam.nix
    ./sway.nix
    ./zsh.nix
  ];

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
    socat
    tree
    wl-clipboard
  ];
}
