{...}: {
  imports = [
    ./coredns.nix
    ./database.nix
    ./git.nix
    ./homeassistant.nix
    ./iperf3.nix
    ./proxy.nix
    ./qbittorrent.nix
    ./smb.nix
    ./vaultwarden.nix
  ];
}
