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
            # node_exporter on the host bridge IP plus every VM in the registry.
            targets = ["10.28.34.1:9100"] ++ lib.mapAttrsToList (_: vm: "10.28.34.${toString vm.index}:9100") (import ../../vm-registry.nix);
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
