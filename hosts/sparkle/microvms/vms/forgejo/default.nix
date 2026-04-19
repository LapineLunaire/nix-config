{outputs, ...}: {
  microvm.vms.forgejo = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.forgejo;
  };

  systemd.network.networks."10-forgejo" = {
    matchConfig.Name = "forgejo";
    networkConfig.Bridge = "vm-br0";
  };
}
