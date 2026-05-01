{...}: {
  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.extraInputRules = ''
    ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 5201 accept
  '';
}
