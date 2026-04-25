{outputs, ...}: {
  microvm.vms.forgejo = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.forgejo;
  };

  systemd.services."microvm@forgejo" = {
    after = ["microvm@postgres.service"];
    wants = ["microvm@postgres.service"];
  };

  systemd.network.networks."10-forgejo" = {
    matchConfig.Name = "forgejo";
    networkConfig.Bridge = "vm-br0";
  };
}
