{outputs, ...}: {
  microvm.vms.authelia = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.authelia;
  };

  systemd.services."microvm@authelia" = {
    after = ["microvm@postgres.service"];
    wants = ["microvm@postgres.service"];
  };

  systemd.network.networks."10-authelia" = {
    matchConfig.Name = "authelia";
    networkConfig.Bridge = "vm-br0";
  };
}
