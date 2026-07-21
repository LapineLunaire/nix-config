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
    ++ lib.optionals config.userConfig.gui (
      with pkgs; [
        alejandra
        azahar
        bat
        brave
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
        texliveFull
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
        alsa-ucm-conf
        discord
        fluffychat
        heroic
        high-tide
        minisign
        mission-center
        mpv
        pciutils
        prismlauncher
        tibia
        usbutils
        wootility
        xivlauncher
      ]
    );
}
