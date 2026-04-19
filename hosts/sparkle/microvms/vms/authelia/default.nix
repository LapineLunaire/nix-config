{outputs, ...}: {
  microvm.vms.authelia = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.authelia;
  };

  systemd.network.networks."10-authelia" = {
    matchConfig.Name = "authelia";
    networkConfig.Bridge = "vm-br0";
  };
}
