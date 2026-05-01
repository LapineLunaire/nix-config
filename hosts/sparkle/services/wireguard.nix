{config, ...}: {
  networking.firewall.interfaces.wg0.allowedTCPPorts = [9000];

  # Caddy binds to the WireGuard IP, so it must start after the interface is up.
  systemd.services.caddy.after = ["wg-quick-wg0.service"];
  systemd.services.caddy.wants = ["wg-quick-wg0.service"];

  networking.wg-quick.interfaces.wg0 = {
    address = ["10.73.212.2/24"];
    privateKeyFile = config.sops.secrets."wireguard-private-key".path;
    peers = [
      {
        # sparxie
        publicKey = "VjVuhnnTEHuGssQOp0iM1yU0BLT34VWm3k00e8tDkSg=";
        allowedIPs = ["10.73.212.1/32"];
        endpoint = "46.225.108.230:47329";
        persistentKeepalive = 25;
      }
    ];
  };
}
