{...}: {
  services.smartd.notifications.mail = {
    enable = true;
    sender = "noreply@lunaire.eu";
    recipient = "lapine@lunaire.eu";
  };

  # node_exporter on sparkle, bound to vm-br0 so the monitoring VM can scrape it.
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "10.28.34.1";
    port = 9100;
  };

  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.19 tcp dport 9100 accept
  '';
}
