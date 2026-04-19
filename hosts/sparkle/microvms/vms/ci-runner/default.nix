{outputs, ...}: {
  microvm.vms.ci-runner = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.ci-runner;
  };

  systemd.network.networks."10-ci-runner" = {
    matchConfig.Name = "ci-runner";
    networkConfig.Bridge = "vm-br0";
  };
}
