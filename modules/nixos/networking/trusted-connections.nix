{
  config,
  lib,
  pkgs,
  ...
}: let
  uuids = config.host.trustedConnections;
  ports = lib.concatMapStringsSep ", " toString (config.services.openssh.ports ++ config.host.trustedTCPPorts);
  nmcli = "${config.networking.networkmanager.package}/bin/nmcli";
  sync = pkgs.writeShellScript "sync-trusted-interfaces" ''
    set -u
    elements=""
    for uuid in ${lib.escapeShellArgs uuids}; do
      iface=$(${nmcli} -g GENERAL.IP-IFACE connection show --active "$uuid" 2> /dev/null) || continue
      [ -n "$iface" ] && elements="$elements \"$iface\","
    done
    {
      echo "flush set inet trusted-connections interfaces"
      [ -z "$elements" ] || echo "add element inet trusted-connections interfaces {$elements }"
    } | ${pkgs.nftables}/bin/nft -f -
  '';
in {
  options.host.trustedConnections = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "UUIDs of the NetworkManager connections whose interfaces may carry SSH and trusted TCP services from the trusted subnets.";
  };

  config = {
    # Require a trusted connection too: other networks may reuse trusted subnets.
    networking.nftables.tables.trusted-connections = {
      family = "inet";
      content = ''
        set interfaces {
          type ifname
        }

        chain input {
          type filter hook input priority filter - 1;
          tcp dport { ${ports} } iifname != "lo" iifname != @interfaces drop
        }
      '';
    };

    networking.networkmanager.dispatcherScripts = [{source = sync;}];

    # Loading the rules empties the set, so refill it. Ignore failures while NetworkManager is not running yet at boot.
    systemd.services.nftables.serviceConfig = {
      ExecStartPost = lib.mkAfter ["-${sync}"];
      ExecReload = lib.mkAfter ["-${sync}"];
    };
  };
}
