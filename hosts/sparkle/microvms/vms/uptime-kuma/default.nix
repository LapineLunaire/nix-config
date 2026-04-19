{outputs, ...}: {
  microvm.vms.uptime-kuma = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.uptime-kuma;
  };

  systemd.network.networks."10-uptime-kuma" = {
    matchConfig.Name = "uptime-kuma";
    networkConfig.Bridge = "vm-br0";
  };
}
