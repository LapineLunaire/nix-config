{lib, ...}: {
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # br_netfilter routes bridged frames through the inet forward chain, without which same-bridge VM-to-VM traffic bypasses the forward-allow rules below entirely.
  boot.kernelModules = ["br_netfilter"];
  boot.kernel.sysctl."net.bridge.bridge-nf-call-iptables" = 1;
  boot.kernel.sysctl."net.bridge.bridge-nf-call-ip6tables" = 1;

  # Bridge for VM TAP interfaces. Sparkle uses systemd-networkd exclusively; do NOT use networking.bridges (scripted networking) alongside networkd.
  systemd.network.netdevs."10-vm-br0" = {
    netdevConfig = {
      Kind = "bridge";
      Name = "vm-br0";
    };
  };
  systemd.network.networks."10-vm-br0" = {
    matchConfig.Name = "vm-br0";
    networkConfig = {
      Address = "10.28.34.1/24";
      # Assign the address even before any TAP interfaces join the bridge.
      ConfigureWithoutCarrier = true;
    };
    linkConfig = {
      # Don't block systemd-networkd-wait-online; bridge has no carrier until the first VM TAP attaches.
      RequiredForOnline = "no";
    };
  };

  # Default-drop on the forward chain. VMs can reach the internet via sfp0 and each other only through the explicit allowlist below.
  networking.firewall.filterForward = true;

  # Caddy→VM traffic hits the OUTPUT chain (Caddy runs on the host), not FORWARD. These rules cover VM-to-VM and VM→internet flows. Per-VM ingress allowlists live alongside each VM definition; the terminal drop is mkAfter'd so they always land before it.
  networking.firewall.extraForwardRules = lib.mkMerge [
    ''
      ct state established,related accept
      iifname "vm-br0" oifname "sfp0" accept
      # LAN/VPN → VMs: SSH and ICMP only.
      iifname "sfp0" oifname "vm-br0" ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 22 accept
      iifname "sfp0" oifname "vm-br0" ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } icmp type echo-request accept

      # monitoring: scrape node_exporter on all VMs.
      iifname "vm-br0" oifname "vm-br0" ip saddr 10.28.34.19 tcp dport 9100 accept
    ''
    (lib.mkAfter ''
      iifname "vm-br0" drop
    '')
  ];

  # VMs resolve via host CoreDNS.
  networking.firewall.interfaces.vm-br0 = {
    allowedUDPPorts = [53];
    allowedTCPPorts = [53];
  };
}
