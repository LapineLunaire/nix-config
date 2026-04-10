{
  config,
  pkgs,
  ...
}: {
  systemd.services.forgejo.serviceConfig.EnvironmentFile = config.sops.templates."forgejo.env".path;

  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    settings = {
      server = {
        DOMAIN = "git.lunaire.moe";
        ROOT_URL = "https://git.lunaire.moe/";
        HTTP_PORT = 3000;
      };
      mailer = {
        ENABLED = true;
        SMTP_ADDR = "smtp.protonmail.ch";
        SMTP_PORT = 587;
        FROM = "Forgejo <noreply@lunaire.eu>";
        USER = "noreply@lunaire.eu";
      };
      service = {
        DISABLE_REGISTRATION = true;
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
      };
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.sparkle = {
      enable = true;
      name = "sparkle";
      url = "https://git.lunaire.moe";
      tokenFile = config.sops.templates."forgejo-runner-token.env".path;
      labels = [
        "debian:docker://node:25@sha256:3953ec6a2c10154a58ccf4ba48083ddfe3f8641d63f0d1d5cb8a4a78169123a7"
      ];
      settings = {
        runner.capacity = 1;
        container = {
          network = "bridge";
          docker_host = "-";
          pull_policy = "if-not-present";
        };
      };
    };
  };

  systemd.services.gitea-runner-sparkle = {
    after = ["forgejo.service"];
    requires = ["forgejo.service"];
    # Prevent restarting mid-run CI jobs on nixos-rebuild switch.
    # Config changes require a manual: systemctl restart gitea-runner-sparkle
    restartIfChanged = false;
    serviceConfig.SupplementaryGroups = ["docker"];
  };
}
