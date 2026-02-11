{
  config,
  lib,
  osConfig,
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
      sops
      ssh-to-age
      traceroute
      tree
      whois
    ])
    ++ lib.optionals config.userConfig.desktop.enable (with pkgs; [
      bat
      brightnessctl
      discord
      duf
      elysia
      eza
      ffmpeg-full
      fluffychat
      firefox
      gping
      grim
      heroic
      imv
      minisign
      mpv
      nmap
      playerctl
      protonmail-desktop
      protonvpn-gui
      rclone
      slurp
      tidal-hifi
      winbox4
      wl-clipboard
      yt-dlp
    ])
    ++ lib.optionals (osConfig.networking.hostName == "camellya") (with pkgs; [
      wootility
    ]);
}
