# Client subnets trusted to reach admin surfaces (Caddy vhosts, VM SSH and ICMP, iperf3): LAN (10.28.64.0/24), WireGuard VPN (10.28.96.0/24), Nox's LAN (10.100.0.0/24), Nox's WireGuard (10.1.0.0/24).
# Imported by services/proxy.nix, services/iperf3.nix, microvms/network.nix, and microvms/vms/forgejo/config.nix; nftSet is the comma-joined form for nftables set literals.
let
  subnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];
in {
  inherit subnets;
  nftSet = builtins.concatStringsSep ", " subnets;
}
