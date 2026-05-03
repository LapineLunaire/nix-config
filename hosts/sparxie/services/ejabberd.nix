{
  config,
  pkgs,
  ...
}: {
  services.ejabberd = {
    enable = true;
    package = pkgs.ejabberd.override {
      withRedis = true;
      withPgsql = true;
    };
    configFile = config.sops.templates."ejabberd.yml".path;
  };

  systemd.services.ejabberd = {
    after = [
      "postgresql.service"
      "redis.service"
    ];
    requires = [
      "postgresql.service"
      "redis.service"
    ];
  };

  networking.firewall = {
    # 5222: XMPP c2s STARTTLS, 5223: XMPP c2s Direct TLS, 5269: XMPP s2s, 5443: HTTPS (BOSH/upload/admin), 3478 UDP: STUN/TURN
    allowedTCPPorts = [
      5222
      5223
      5269
      5443
    ];
    allowedUDPPorts = [3478];
  };
}
