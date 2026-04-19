{...}: {
  imports = [
    ./backup.nix
    ./coredns.nix
    ./monitoring.nix
    ./iperf3.nix
    ./proxy.nix
    ./smb.nix
    ./wireguard.nix
  ];
}
