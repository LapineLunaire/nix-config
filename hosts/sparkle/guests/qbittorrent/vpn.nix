{
  config,
  pkgs,
  web,
  ...
}: let
  forwardedPort = 57140;
  webuiPort = toString web.endpoints.qbittorrent.port;
  wireguardConfig = config.sops.secrets."qbittorrent-protonvpn-conf".path;

  firewall = pkgs.writeText "qbtvpn.nft" ''
    table inet qbtvpn {
      chain input {
        type filter hook input priority filter; policy drop;
        iif lo accept
        ct state invalid drop
        ct state established,related accept
        iifname "qbtvpn0" meta l4proto { tcp, udp } th dport ${toString forwardedPort} accept
      }

      chain forward {
        type filter hook forward priority filter; policy drop;
      }
    }
  '';

  # Hide the guest's resolvers so lookups use the VPN's DNS.
  confined = {
    bindsTo = ["qbtvpn.service"];
    after = ["qbtvpn.service"];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/qbtvpn";
      BindReadOnlyPaths = ["/run/qbtvpn/resolv.conf:/etc/resolv.conf:norbind"];
      InaccessiblePaths = ["-/run/nscd" "-/run/resolvconf"];
    };
  };
in {
  # The namespace holds only loopback and the tunnel, so traffic has no route around the VPN.
  systemd.services.qbtvpn = {
    description = "qBittorrent VPN namespace";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    # Bound services stop with the namespace but do not start with it.
    wants = ["network-online.target" "qbittorrent.service"];
    path = with pkgs; [gnused iproute2 nftables wireguard-tools];
    script = ''
      # wg-quick accepts inline comments and CRLF line endings.
      config=$(sed -E 's/\r$//; s/\s*#.*$//' ${wireguardConfig})

      setting() {
        sed -nE "s/^\s*$1\s*=\s*//Ip" <<< "$config" | tr ',' ' '
      }

      ip netns add qbtvpn
      ip -n qbtvpn link set lo up
      ip netns exec qbtvpn nft -f ${firewall}

      # Create the tunnel here and move it, so its encrypted traffic stays on the guest network.
      ip link add qbtvpn0 type wireguard
      ip link set qbtvpn0 netns qbtvpn
      ip netns exec qbtvpn wg setconf qbtvpn0 \
        <(sed -E '/^\s*(Address|DNS|MTU|Table|PreUp|PostUp|PreDown|PostDown|SaveConfig)\s*=/Id' <<< "$config")

      for address in $(setting Address); do
        ip -n qbtvpn address add "$address" dev qbtvpn0
      done
      for server in $(setting DNS); do
        echo "nameserver $server"
      done > /run/qbtvpn/resolv.conf

      mtu=$(setting MTU)
      ip -n qbtvpn link set qbtvpn0 mtu "''${mtu:-1420}" up
      ip -n qbtvpn route add default dev qbtvpn0
      ip -6 -n qbtvpn route add default dev qbtvpn0
    '';
    postStop = "ip netns delete qbtvpn || true";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "qbtvpn";
    };
  };

  systemd.services.qbittorrent = confined;
  services.qbittorrent.torrentingPort = forwardedPort;

  # The web UI is reached through a socket on the guest network, passed into the namespace.
  # The socket follows the namespace because a proxy that cannot start would trip its trigger limit.
  systemd.sockets.qbittorrent-webui = {
    wantedBy = ["qbtvpn.service"];
    bindsTo = ["qbtvpn.service"];
    after = ["qbtvpn.service"];
    unitConfig.DefaultDependencies = false;
    listenStreams = [webuiPort];
  };
  systemd.services.qbittorrent-webui = {
    bindsTo = ["qbtvpn.service"];
    after = ["qbtvpn.service"];
    serviceConfig = {
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${webuiPort}";
      NetworkNamespacePath = "/run/netns/qbtvpn";
      DynamicUser = true;
    };
  };
}
