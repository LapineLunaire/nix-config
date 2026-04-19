{...}: {
  imports = [
    ./network.nix
    ./vms/uptime-kuma
    ./vms/monitoring
    ./vms/kavita
    ./vms/ci-runner
    ./vms/postgres
    ./vms/authelia
    ./vms/forgejo
    ./vms/vaultwarden
    ./vms/pgadmin
    ./vms/homeassistant
    ./vms/qbittorrent
  ];
}
