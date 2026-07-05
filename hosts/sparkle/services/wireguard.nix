{config, ...}: let
  wg = import ../../../modules/nixos/sparkle-sparxie-wireguard.nix;
in {
  networking.firewall.interfaces.wg0.allowedTCPPorts = [9000];

  # Caddy binds to the WireGuard IP, so it must start after the interface is up.
  systemd.services.caddy.after = ["wg-quick-wg0.service"];
  systemd.services.caddy.wants = ["wg-quick-wg0.service"];

  networking.wg-quick.interfaces.wg0 = {
    address = ["${wg.sparkle.ip}/${wg.prefixLength}"];
    privateKeyFile = config.sops.secrets."wireguard-private-key".path;
    peers = [
      {
        publicKey = wg.sparxie.publicKey;
        allowedIPs = ["${wg.sparxie.ip}/32"];
        endpoint = "${(import ../../sparxie/public-addresses.nix).ipv4}:${toString wg.listenPort}";
        persistentKeepalive = 25;
      }
    ];
  };
}
