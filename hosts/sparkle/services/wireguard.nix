{config, ...}: let
  wg = config.site.wireguardTunnel;
in {
  networking.firewall.interfaces.wg0.allowedTCPPorts = [9000];

  # Caddy binds to the WireGuard IP, so it must start after the interface is up.
  systemd.services.caddy.after = ["wg-quick-wg0.service"];
  systemd.services.caddy.wants = ["wg-quick-wg0.service"];

  networking.wg-quick.interfaces.wg0 = {
    address = ["${wg.local.ip}/${wg.prefixLength}"];
    privateKeyFile = config.sops.secrets."wireguard-private-key".path;
    peers = [
      {
        publicKey = wg.peer.publicKey;
        allowedIPs = ["${wg.peer.ip}/32"];
        endpoint = wg.peer.endpoint;
        persistentKeepalive = 25;
      }
    ];
  };
}
