{
  config,
  lib,
  pkgs,
  inputs,
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
    ++ lib.optionals config.userConfig.desktop.enable (
      [inputs.nixd.packages.${pkgs.stdenv.hostPlatform.system}.nixd]
      ++ (with pkgs; [
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
        mpv
        nmap
        playerctl
        protonmail-desktop
        protonvpn-gui
        rclone
        slurp
        winbox4
        wl-clipboard
        yt-dlp
      ])
    );
}
