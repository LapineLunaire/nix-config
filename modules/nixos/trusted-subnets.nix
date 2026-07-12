# Client subnets trusted to reach admin surfaces (Caddy vhosts, the sparkle and camellya sshd ingress, forgejo git-ssh, VM ICMP, Samba, iperf3): LAN (10.28.64.0/24), WireGuard VPN (10.28.96.0/24), Nox's LAN (10.100.0.0/24), Nox's WireGuard (10.1.0.0/24).
# Imported by the sparkle and camellya default.nix, sparkle's services/{proxy,iperf3,smb}.nix, microvms/network.nix, and microvms/vms/forgejo/config.nix; nftSet is the comma-joined form for nftables set literals.
let
  subnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];
in {
  inherit subnets;
  nftSet = builtins.concatStringsSep ", " subnets;
}
