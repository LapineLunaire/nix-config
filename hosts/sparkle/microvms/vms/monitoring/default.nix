{outputs, ...}: {
  microvm.vms.monitoring = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.monitoring;
  };

  systemd.network.networks."10-monitoring" = {
    matchConfig.Name = "monitoring";
    networkConfig.Bridge = "vm-br0";
  };
}
