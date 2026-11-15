{
  config,
  lib,
  dmz,
  net,
  web,
  guestRegistry,
  trustedSubnets,
  guestConfigurations,
  ...
}: {
  # Use bridge conntrack. br_netfilter hides the tap names these rules need.
  boot.kernelModules = ["nf_conntrack_bridge"];

  systemd.network.netdevs."10-${dmz.bridge}" = {
    netdevConfig = {
      Kind = "bridge";
      Name = dmz.bridge;
    };
  };
  systemd.network.networks."10-${dmz.bridge}" = {
    matchConfig.Name = dmz.bridge;
    networkConfig = {
      Address = "${dmz.hostAddress}/${toString dmz.prefixLength}";
      Gateway = dmz.gateway;
      ConfigureWithoutCarrier = true;
    };
  };

  # Drop routed forwarding; guest traffic uses the bridge rules below.
  networking.firewall.filterForward = true;

  # Filter traffic between taps and sfp0. Traffic to Sparkle itself uses its input firewall.
  networking.nftables.tables.dmz = let
    trusted = config.host.trustedSubnetsNft;
    # Include the router that repeats LAN discovery.
    discoverySources = "${trustedSubnets.lan}, ${dmz.gateway}";
    guests = net.tapsNft;
    forgejoSshPorts = lib.concatMapStringsSep ", " toString guestConfigurations.forgejo.config.services.openssh.ports;
    guestMacsNft = lib.concatStringsSep ", " (lib.mapAttrsToList (name: _: "\"${name}\" . ${(builtins.head guestConfigurations.${name}.config.microvm.interfaces).mac}") guestRegistry);
    # Flows without their own destinations exclude these private, multicast and reserved ranges.
    privateSpace = "{ 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16, 224.0.0.0/3 }";
    renderFlow = tap: flow: let
      destination =
        if flow.destinations == []
        then "ip daddr != ${privateSpace}"
        else "ip daddr { ${lib.concatStringsSep ", " flow.destinations} }";
      portSet = dir: list: lib.optionalString (flow.proto != "icmp" && list != []) " ${flow.proto} ${dir} { ${lib.concatMapStringsSep ", " toString list} }";
      sports = portSet "sport" flow.sourcePorts;
      ports = portSet "dport" flow.ports;
      # Port matches imply the protocol; unbounded flows need an explicit match.
      match =
        if flow.proto == "icmp"
        then " icmp type echo-request"
        else lib.optionalString (flow.ports == [] && flow.sourcePorts == []) " meta l4proto ${flow.proto}";
    in "iifname \"${tap}\" oifname \"sfp0\" ${destination}${match}${sports}${ports} accept";
    egressRules = lib.concatStringsSep "\n" (lib.concatLists (lib.mapAttrsToList (name: _:
      map (renderFlow name) guestConfigurations.${name}.config.microvmGuest.egress)
    guestRegistry));
  in {
    family = "bridge";
    content = ''
      set guest-identity {
        type ifname . ipv4_addr
        elements = { ${net.guestIdentityNft} }
      }

      set guest-mac {
        type ifname . ether_addr
        elements = { ${guestMacsNft} }
      }

      # Drop spoofed sources before bridge conntrack (-200) sees them.
      chain antispoof {
        type filter hook prerouting priority -300; policy accept;

        iifname != { ${guests} } accept

        # Validate before MAC learning, so a guest cannot move another guest's bridge entry.
        iifname . ether saddr != @guest-mac goto spoof-drop

        # Guests are IPv4-only.
        ether type != { ip, arp } drop

        ether type ip iifname . ip saddr != @guest-identity goto spoof-drop
        # Check the ARP payload as well as the Ethernet source.
        ether type arp iifname . arp saddr ip != @guest-identity goto spoof-drop
      }

      chain spoof-drop {
        limit rate 10/second log prefix "guest-spoof-drop "
        drop
      }

      chain forward {
        type filter hook forward priority filter; policy drop;

        # Allow ARP after validating guest identities.
        ether type arp accept

        ct state invalid drop
        ct state established,related accept

        # Trusted subnets: Git over SSH to Forgejo, and ICMP to any guest.
        iifname "sfp0" oifname "forgejo" ip saddr { ${trusted} } tcp dport { ${forgejoSshPorts} } accept
        iifname "sfp0" oifname { ${guests} } ip saddr { ${trusted} } icmp type echo-request accept

        # Uptime Kuma checks Forgejo's Git-over-SSH service.
        iifname "uptime-kuma" oifname "forgejo" tcp dport { ${forgejoSshPorts} } accept

        # monitoring: scrape node_exporter on every guest.
        iifname "monitoring" oifname { ${guests} } tcp dport ${toString net.nodeExporterPort} accept

        # PostgreSQL, from the client guests listed in guest-net.nix.
        iifname { ${guests} } oifname "postgres" tcp dport ${toString net.postgresPort} ip saddr { ${net.postgresClientsNft} } accept

        # NFSv4 only, so TCP 2049 is enough; allow the client guests listed in guest-net.nix.
        iifname { ${guests} } oifname "vault" tcp dport ${toString net.nfsPort} ip saddr { ${net.nfsClientsNft} } accept

        # SMB is for trusted clients; guests use NFS.
        iifname "sfp0" oifname "vault" ip saddr { ${trusted} } tcp dport { 139, 445 } accept
        # NetBIOS and wsdd discovery from the LAN and its repeater.
        iifname "sfp0" oifname "vault" ip saddr { ${discoverySources} } udp dport { 137, 138 } accept
        iifname "sfp0" oifname "vault" ip saddr { ${discoverySources} } tcp dport 5357 accept
        # Match multicast destinations; repeated discovery may have the router's source address.
        iifname "sfp0" oifname "vault" ip daddr 224.0.0.251 udp dport 5353 accept
        iifname "sfp0" oifname "vault" ip daddr 239.255.255.250 udp dport 3702 accept

        # DNS serves every client inside the perimeter.
        iifname { ${guests} } oifname "dns" udp dport 53 accept
        iifname { ${guests} } oifname "dns" tcp dport 53 accept
        iifname "sfp0" oifname "dns" udp dport 53 accept
        iifname "sfp0" oifname "dns" tcp dport 53 accept

        # HTTP and HTTPS, including HTTP/3. Each vhost also checks its source-IP allowlist.
        iifname "sfp0" oifname "proxy" ip saddr { ${trusted}, ${dmz.subnet} } tcp dport { 80, 443 } accept
        iifname "sfp0" oifname "proxy" ip saddr { ${trusted}, ${dmz.subnet} } udp dport 443 accept
        # HTTPS, including HTTP/3, for health checks, OIDC backchannels and CI requests.
        iifname { "uptime-kuma", "forgejo", "pgadmin", "ci-runner" } oifname "proxy" tcp dport 443 accept
        iifname { "uptime-kuma", "forgejo", "pgadmin", "ci-runner" } oifname "proxy" udp dport 443 accept
        # The proxy reaches each backend on the port guest-web.nix gives it.
        ${lib.concatStrings (lib.mapAttrsToList (name: e: "iifname \"proxy\" oifname \"${name}\" tcp dport ${toString e.port} accept\n") web.endpoints)}

        # Allow only the egress declared by each guest.
        ${egressRules}

        # Drop multicast copies flooded to other taps without logging them.
        iifname "vault" ip daddr { 224.0.0.251, 239.255.255.250 } drop

        iifname { ${guests} } limit rate 10/second log prefix "guest-egress-drop "
      }
    '';
  };
}
