{
  config,
  lib,
  dmz,
  net,
  ...
}: {
  imports = [
    ../../modules/nixos/services/mail-relay.nix
    ../../modules/nixos/services/smartd.nix
  ];

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = dmz.hostAddress;
    port = net.nodeExporterPort;
  };

  networking.firewall.extraInputRules = ''
    ip saddr ${net.vmAddress.monitoring} tcp dport ${toString net.nodeExporterPort} accept
    # Uptime Kuma checks the host's SSH service through the input firewall.
    ip saddr ${net.vmAddress.uptime-kuma} tcp dport { ${lib.concatMapStringsSep ", " toString config.services.openssh.ports} } accept
  '';
}
