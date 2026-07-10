{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."grafana-secret-key".owner = "grafana";
    secrets."grafana-admin-password".owner = "grafana";
  };

  services.grafana.settings.security = {
    secret_key = "$__file{${config.sops.secrets."grafana-secret-key".path}}";
    # Seeds the admin account when grafana creates its database; an existing database keeps its stored password (rotate via the UI or grafana-cli admin reset-admin-password).
    admin_password = "$__file{${config.sops.secrets."grafana-admin-password".path}}";
  };
}
