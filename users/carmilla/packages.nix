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
      iperf3
      jq
      ldns
      mtr
      nvimpager
      ripgrep
      rclone
      rsync
      socat
      sops
      ssh-to-age
      yubikey-manager
      tree
      whois
    ])
    ++ lib.optionals (config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin) (with pkgs; [
      bat
      discord
      duf
      eza
      firefox
      gping
      nmap
      protonmail-desktop
      proton-vpn
      winbox4
      yt-dlp
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (with pkgs; [
      iina
      neovim
      utm
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
      traceroute
    ])
    ++ lib.optionals config.userConfig.desktop.enable (with pkgs; [
      brightnessctl
      elysia
      ffmpeg-full
      fluffychat
      gcr
      grim
      heroic
      libsecret
      imv
      minisign
      mpv
      pciutils
      playerctl
      slurp
      tidal-hifi
      usbutils
      wl-clipboard
      xivlauncher
    ])
    ++ lib.optionals (osConfig.networking.hostName == "camellya") (with pkgs; [
      wootility
    ]);
}
