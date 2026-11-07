{
  config,
  lib,
  ...
}: let
  wg = config.host.wireguardTunnel;
in {
  options.host.wireguardTunnel = {
    prefixLength = lib.mkOption {
      type = lib.types.str;
      description = "Prefix length for the tunnel addresses.";
    };

    listenPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "UDP listening port, or null for an outgoing connection.";
    };

    local.ip = lib.mkOption {
      type = lib.types.str;
      description = "This system's tunnel address.";
    };

    peer = {
      ip = lib.mkOption {
        type = lib.types.str;
        description = "The peer's tunnel address.";
      };

      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "The peer's WireGuard public key.";
      };

      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Peer host and port, or null to wait for the peer to connect.";
      };
    };
  };

  config = {
    sops.secrets."wireguard-private-key".restartUnits = ["wg-quick-wg0.service"];

    networking.firewall.allowedUDPPorts = lib.optionals (wg.listenPort != null) [wg.listenPort];

    networking.wg-quick.interfaces.wg0 = {
      address = ["${wg.local.ip}/${wg.prefixLength}"];
      inherit (wg) listenPort;
      privateKeyFile = config.sops.secrets."wireguard-private-key".path;
      peers = [
        {
          inherit (wg.peer) publicKey endpoint;
          allowedIPs = ["${wg.peer.ip}/32"];
          persistentKeepalive = lib.mkIf (wg.peer.endpoint != null) 25;
        }
      ];
    };
  };
}
