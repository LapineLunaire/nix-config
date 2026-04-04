{config, ...}: {
  networking.firewall.allowedUDPPorts = [47329];

  networking.wg-quick.interfaces.wg0 = {
    address = ["10.73.212.1/24"];
    listenPort = 47329;
    privateKeyFile = config.sops.secrets."wireguard-private-key".path;
    peers = [
      {
        # sparkle
        publicKey = "fU36EC/ymy4d1XwJCfqAXKEX8dRK/WuMFBbh6OtKBRM=";
        allowedIPs = ["10.73.212.2/32"];
      }
    ];
  };
}
