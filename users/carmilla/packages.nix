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
      iperf3
      jq
      ldns
      mtr
      nvimpager
      rclone
      ripgrep
      rsync
      socat
      sops
      ssh-to-age
      whois
      xh
      yubikey-manager
    ])
    ++ lib.optionals (config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin) (
      with pkgs; [
        alejandra
        azahar
        bat
        duf
        eza
        ffmpeg-full
        firefox
        gping
        megatools
        nixd
        nmap
        pandoc
        proton-vpn
        protonmail-desktop
        texlive.combined.scheme-full
        winbox4
        yt-dlp
      ]
    )
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
      with pkgs; [
        iina
        utm
      ]
    )
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs; [
        traceroute
      ]
    )
    ++ lib.optionals config.userConfig.desktop.enable (
      with pkgs; [
        brightnessctl
        discord
        elysia
        fluffychat
        gcr
        grim
        heroic
        imv
        libsecret
        minisign
        mpv
        pciutils
        playerctl
        slurp
        tibia
        tidal-hifi
        usbutils
        wl-clipboard
        wootility
        xivlauncher
      ]
    );
}
