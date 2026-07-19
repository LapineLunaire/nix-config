{config, ...}: let
  wg = config.site.wireguardTunnel;
in {
  networking.firewall.allowedUDPPorts = [wg.listenPort];

  networking.wg-quick.interfaces.wg0 = {
    address = ["${wg.local.ip}/${wg.prefixLength}"];
    listenPort = wg.listenPort;
    privateKeyFile = config.sops.secrets."wireguard-private-key".path;
    peers = [
      {
        publicKey = wg.peer.publicKey;
        allowedIPs = ["${wg.peer.ip}/32"];
      }
    ];
  };
}
