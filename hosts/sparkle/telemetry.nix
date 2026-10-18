{config, ...}: let
  dmz = import ./dmz-net.nix;
  net = import ./guest-net.nix;
in {
  imports = [
    ../../modules/nixos/services/mail-relay.nix
    ../../modules/nixos/services/smartd.nix
  ];

  services.smartd.notifications.mail = {
    enable = true;
    sender = config.host.smtp.user;
    recipient = "carmilla@lunaire.eu";
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = dmz.hostAddress;
    port = net.nodeExporterPort;
  };

  networking.firewall.extraInputRules = ''
    ip saddr ${net.vmAddress.monitoring} tcp dport ${toString net.nodeExporterPort} accept
    # Uptime Kuma checks the host's SSH service through the input firewall.
    ip saddr ${net.vmAddress.uptime-kuma} tcp dport 22 accept
  '';
}
