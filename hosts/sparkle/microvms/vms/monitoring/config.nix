{lib, ...}: {
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
            targets = [
              "10.28.34.1:9100"
              "10.28.34.10:9100"
              "10.28.34.11:9100"
              "10.28.34.12:9100"
              "10.28.34.13:9100"
              "10.28.34.14:9100"
              "10.28.34.15:9100"
              "10.28.34.16:9100"
              "10.28.34.17:9100"
              "10.28.34.18:9100"
              "10.28.34.19:9100"
              "10.28.34.20:9100"
              "10.28.34.21:9100"
            ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "10.28.34.19";
      http_port = 3000;
      domain = "gf.lunaire.moe";
      root_url = "https://gf.lunaire.moe/";
    };
  };

  networking.firewall.extraInputRules = lib.mkAfter ''
    ip saddr 10.28.34.1 tcp dport 3000 accept
  '';
}
