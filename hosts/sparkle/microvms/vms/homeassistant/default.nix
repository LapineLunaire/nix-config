{outputs, ...}: {
  microvm.vms.homeassistant = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.homeassistant;
  };

  systemd.network.networks."10-homeassistant" = {
    matchConfig.Name = "homeassistant";
    networkConfig.Bridge = "vm-br0";
  };
}
