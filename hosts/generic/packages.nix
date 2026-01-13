{
  config,
  lib,
  pkgs,
  ...
}: {
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

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 3";
      dates = "daily";
    };
    flake = "/etc/nixos";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs;
    [
      curl
      fd
      fzf
      jq
      ripgrep
      rsync
      smartmontools
      socat
      tree
    ]
    ++ lib.optionals config.hostConfig.desktop.enable [
      brightnessctl
      grim
      playerctl
      slurp
      wl-clipboard
    ];
}
