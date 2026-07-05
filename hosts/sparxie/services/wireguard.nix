{config, ...}: let
  wg = import ../../../modules/nixos/sparkle-sparxie-wireguard.nix;
in {
  networking.firewall.allowedUDPPorts = [wg.listenPort];

  networking.wg-quick.interfaces.wg0 = {
    address = ["${wg.sparxie.ip}/${wg.prefixLength}"];
    listenPort = wg.listenPort;
    privateKeyFile = config.sops.secrets."wireguard-private-key".path;
    peers = [
      {
        publicKey = wg.sparkle.publicKey;
        allowedIPs = ["${wg.sparkle.ip}/32"];
      }
    ];
  };
}
