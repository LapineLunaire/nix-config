{...}: {
  imports = [
    ./cloudflared.nix
    ./coredns.nix
    ./filebrowser.nix
    ./database.nix
    ./git.nix
    ./homeassistant.nix
    ./iperf3.nix
    ./proxy.nix
    ./qbittorrent.nix
    ./smb.nix
    ./uptime-kuma.nix
    ./vaultwarden.nix
  ];
}
