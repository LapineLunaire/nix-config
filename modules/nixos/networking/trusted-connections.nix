{
  config,
  lib,
  pkgs,
  ...
}: let
  uuids = config.host.trustedConnections;
  ports = lib.concatMapStringsSep ", " toString config.services.openssh.ports;
  nmcli = "${config.networking.networkmanager.package}/bin/nmcli";
  # Replace the set's contents with the interfaces of the active trusted connections.
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
    description = "UUIDs of the NetworkManager connections whose interfaces may carry SSH from the trusted subnets.";
  };

  config = {
    # Drop SSH before nixos-fw unless it arrives on a trusted connection's interface, so other networks that reuse the trusted subnets are refused.
    networking.nftables.tables.trusted-connections = {
      family = "inet";
      content = ''
        set interfaces {
          type ifname
        }

        chain input {
          type filter hook input priority filter - 1;
          tcp dport { ${ports} } iifname != @interfaces drop
        }
      '';
    };

    networking.networkmanager.dispatcherScripts = [{source = sync;}];

    # Loading the rules empties the set. Ignore failures while NetworkManager is not running yet at boot.
    systemd.services.nftables.serviceConfig = {
      ExecStartPost = lib.mkAfter ["-${sync}"];
      ExecReload = lib.mkAfter ["-${sync}"];
    };
  };
}
