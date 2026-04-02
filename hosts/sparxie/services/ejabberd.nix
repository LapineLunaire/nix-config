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
    after = ["postgresql.service" "redis.service"];
    requires = ["postgresql.service" "redis.service"];
  };

  networking.firewall = {
    allowedTCPPorts = [5222 5223 5269 5443];
    allowedUDPPorts = [3478];
  };
}
