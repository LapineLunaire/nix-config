{lib, ...}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 2048;
    initialBalloonMem = 1024;
    shares = [
      {
        tag = "state";
        source = "/persist/vms/monitoring";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "90d";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            # node_exporter on the host bridge IP plus every VM in the registry.
            targets = ["${net.host}:9100"] ++ lib.mapAttrsToList (_: ip: "${ip}:9100") net.ip;
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = net.ip.monitoring;
      http_port = 3000;
      domain = "gf.lunaire.moe";
      root_url = "https://gf.lunaire.moe/";
    };
  };

  networking.firewall.extraInputRules = lib.mkAfter ''
    ip saddr 10.28.34.1 tcp dport 3000 accept
  '';
}
