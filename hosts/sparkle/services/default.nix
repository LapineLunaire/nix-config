{...}: {
  imports = [
    ./coredns.nix
    ./database.nix
    ./git.nix
    ./iperf3.nix
    ./proxy.nix
    ./qbittorrent.nix
    ./smb.nix
    ./vaultwarden.nix
  ];
}
