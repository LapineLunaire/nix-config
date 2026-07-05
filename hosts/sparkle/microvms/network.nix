{lib, ...}: let
  # Both LANs and both WireGuard subnets (see trusted-subnets.nix), shared with the Caddy vhost ACLs and VM SSH ingress.
  trusted = (import ../trusted-subnets.nix).nftSet;
  net = import ./vm-net.nix;
  postgresClients = lib.concatStringsSep ", " (map (name: net.vmAddress.${name}) net.postgresClients);
  # Management network behind sfp0 where all management surfaces live: routers, switches, IPMI, and the UniFi APs.
  management = "10.28.16.0/24";
in {
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
      Address = "${net.hostAddress}/24";
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

  # Caddy-to-VM traffic hits the OUTPUT chain (Caddy runs on the host), not FORWARD. These rules cover VM-to-VM and VM-to-internet flows. Per-VM ingress allowlists live alongside each VM definition; the terminal drop is mkAfter'd so they always land before it.
  networking.firewall.extraForwardRules = lib.mkMerge [
    ''
      ct state established,related accept
      # VMs reach the internet but not RFC1918 space; LAN flows VMs initiate need explicit rules below.
      iifname "vm-br0" oifname "sfp0" ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept
      # UniFi controller reaches the APs on the management network for adoption, provisioning, and firmware pushes.
      iifname "vm-br0" oifname "sfp0" ip saddr ${net.vmAddress.unifi} ip daddr ${management} accept
      # LAN/VPN to VMs: SSH and ICMP only.
      iifname "sfp0" oifname "vm-br0" ip saddr { ${trusted} } tcp dport 22 accept
      iifname "sfp0" oifname "vm-br0" ip saddr { ${trusted} } icmp type echo-request accept

      # monitoring: scrape node_exporter on all VMs.
      iifname "vm-br0" oifname "vm-br0" ip saddr ${net.vmAddress.monitoring} tcp dport 9100 accept

      # PostgreSQL, from the client VMs listed in vm-net.nix.
      iifname "vm-br0" oifname "vm-br0" ip daddr ${net.vmAddress.postgres} tcp dport 5432 ip saddr { ${postgresClients} } accept

      # UniFi APs reach the controller VM for L3 inform/adoption and service traffic.
      iifname "sfp0" oifname "vm-br0" ip daddr ${net.vmAddress.unifi} ip saddr ${management} tcp dport { 8080, 8443, 6789, 8880, 8843 } accept
      iifname "sfp0" oifname "vm-br0" ip daddr ${net.vmAddress.unifi} ip saddr ${management} udp dport { 3478, 10001 } accept
      # Admins reach the controller web UI directly (no reverse proxy).
      iifname "sfp0" oifname "vm-br0" ip daddr ${net.vmAddress.unifi} ip saddr { ${trusted} } tcp dport 443 accept
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
