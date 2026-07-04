{...}: {
  imports = [
    (import ../../../modules/nixos/borg-backup.nix {
      pool = "sparkle";
      startAt = "02:30";
    })
    ../../../modules/nixos/zfs-maintenance.nix
    ../../../modules/nixos/caddy.nix
    ./coredns.nix
    ./monitoring.nix
    ./iperf3.nix
    ./proxy.nix
    ./smb.nix
    ./wireguard.nix
  ];
}
