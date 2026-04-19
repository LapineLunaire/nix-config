{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."grafana-secret-key".owner = "grafana";
  };

  services.grafana.settings.security.secret_key = "$__file{${config.sops.secrets."grafana-secret-key".path}}";
}
