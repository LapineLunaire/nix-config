{outputs, ...}: {
  microvm.vms.vaultwarden = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.vaultwarden;
  };

  systemd.services."microvm@vaultwarden" = {
    after = ["microvm@postgres.service"];
    wants = ["microvm@postgres.service"];
  };

  systemd.network.networks."10-vaultwarden" = {
    matchConfig.Name = "vaultwarden";
    networkConfig.Bridge = "vm-br0";
  };
}
