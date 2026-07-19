{config, ...}: let
  net = import ../microvms/vm-net.nix;
in {
  services.smartd.enable = true;
  services.smartd.notifications.mail = {
    enable = true;
    sender = config.site.smtp.user;
    recipient = "lapine@lunaire.eu";
  };

  # node_exporter on sparkle, bound to vm-br0 so the monitoring VM can scrape it.
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = net.hostAddress;
    port = 9100;
  };

  networking.firewall.extraInputRules = ''
    ip saddr ${net.vmAddress.monitoring} tcp dport 9100 accept
  '';
}
