{outputs, ...}: {
  imports = [
    (import outputs.nixosModules.borg-backup {
      pool = "sparkle";
      startAt = "02:30";
    })
    outputs.nixosModules.zfs-maintenance
    outputs.nixosModules.caddy
    ./coredns.nix
    ./monitoring.nix
    ./iperf3.nix
    ./proxy.nix
    ./smb.nix
    ./wireguard.nix
  ];
}
