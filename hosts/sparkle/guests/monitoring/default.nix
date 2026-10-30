{
  dmz,
  net,
  web,
  config,
  lib,
  ...
}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 2048;
    initialBalloonMem = 1024;
  };

  # Grafana plugins, dashboards and contact points, including email.
  microvmGuest.egress = [
    {
      proto = "tcp";
      ports = [80 443 587];
    }
  ];

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
            targets = map (ip: "${ip}:${toString net.nodeExporterPort}") ([dmz.hostAddress] ++ lib.attrValues net.vmAddress);
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = net.vmAddress.monitoring;
        http_port = web.endpoints.monitoring.port;
        domain = web.vhost.monitoring;
        root_url = "${web.origin.monitoring}/";
      };
      security = {
        cookie_secure = true;
        secret_key = "$__file{${config.sops.secrets."grafana-secret-key".path}}";
        # Only seeds a new database. Rotate an existing password through Grafana.
        admin_password = "$__file{${config.sops.secrets."grafana-admin-password".path}}";
      };
    };
  };
}
