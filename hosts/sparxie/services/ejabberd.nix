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
    # Wait for postgresql-passwords so the ejabberd role's password is set before the first DB connection.
    after = [
      "postgresql.service"
      "postgresql-passwords.service"
      "redis.service"
    ];
    requires = [
      "postgresql.service"
      "postgresql-passwords.service"
      "redis.service"
    ];
  };

  networking.firewall = {
    # 5222: XMPP c2s STARTTLS, 5223: XMPP c2s Direct TLS, 5269: XMPP s2s, 5443: HTTPS (BOSH/upload/admin), 3478 UDP: STUN/TURN.
    allowedTCPPorts = [
      5222
      5223
      5269
      5443
    ];
    allowedUDPPorts = [3478];
    # TURN relay allocations, matching turn_min_port/turn_max_port in the ejabberd listener.
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 49500;
      }
    ];
  };
}
