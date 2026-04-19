{outputs, ...}: {
  microvm.vms.qbittorrent = {
    autostart = true;
    evaluatedConfig = outputs.nixosConfigurations.qbittorrent;
  };

  systemd.network.networks."10-qbittorrent" = {
    matchConfig.Name = "qbittorrent";
    networkConfig.Bridge = "vm-br0";
  };
}
