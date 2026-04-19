{outputs, ...}: {
  microvm.vms.postgres = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.postgres;
  };

  systemd.network.networks."10-postgres" = {
    matchConfig.Name = "postgres";
    networkConfig.Bridge = "vm-br0";
  };

  # PostgreSQL: app VMs + pgadmin (admin) + uptime-kuma (health check).
  networking.firewall.extraForwardRules = ''
    iifname "vm-br0" oifname "vm-br0" ip daddr 10.28.34.10 tcp dport 5432 ip saddr { 10.28.34.11, 10.28.34.12, 10.28.34.16, 10.28.34.18, 10.28.34.20 } accept
  '';
}
