{outputs, ...}: {
  microvm.vms.pgadmin = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.pgadmin;
  };

  systemd.network.networks."10-pgadmin" = {
    matchConfig.Name = "pgadmin";
    networkConfig.Bridge = "vm-br0";
  };
}
