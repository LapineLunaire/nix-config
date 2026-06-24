{outputs, ...}: {
  microvm.vms.unifi = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.unifi;
  };

  systemd.network.networks."10-unifi" = {
    matchConfig.Name = "unifi";
    networkConfig.Bridge = "vm-br0";
  };
}
