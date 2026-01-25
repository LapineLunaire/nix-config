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
      (ffmpeg-full.override {withUnfree = true;})
      firefox
      gping
      grim
      heroic
      imv
      minisign
      (mpv.override {mpv-unwrapped = mpv-unwrapped.override {ffmpeg = ffmpeg-full.override {withUnfree = true;};};})
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
