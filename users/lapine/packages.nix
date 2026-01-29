{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages =
    (with pkgs; [
      curl
      fd
      fzf
      iperf3
      jq
      ldns
      mtr
      nvimpager
      ripgrep
      rsync
      socat
      traceroute
      tree
      whois
    ])
    ++ lib.optionals config.userConfig.desktop.enable (with pkgs; [
      bat
      brightnessctl
      discord
      duf
      eza
      firefox
      gping
      grim
      heroic
      imv
      minisign
      nmap
      playerctl
      protonmail-desktop
      protonvpn-gui
      rclone
      slurp
      winbox4
      wl-clipboard
      yt-dlp
    ]);
}
