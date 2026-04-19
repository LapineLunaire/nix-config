{outputs, ...}: {
  microvm.vms.vaultwarden = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.vaultwarden;
  };

  systemd.network.networks."10-vaultwarden" = {
    matchConfig.Name = "vaultwarden";
    networkConfig.Bridge = "vm-br0";
  };
}
