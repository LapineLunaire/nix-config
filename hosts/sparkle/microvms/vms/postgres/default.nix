{outputs, ...}: {
  microvm.vms.postgres = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.postgres;
  };

  systemd.network.networks."10-postgres" = {
    matchConfig.Name = "postgres";
    networkConfig.Bridge = "vm-br0";
  };
}
