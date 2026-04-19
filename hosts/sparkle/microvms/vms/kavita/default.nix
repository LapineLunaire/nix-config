{outputs, ...}: {
  microvm.vms.kavita = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.kavita;
  };

  systemd.network.networks."10-kavita" = {
    matchConfig.Name = "kavita";
    networkConfig.Bridge = "vm-br0";
  };
}
