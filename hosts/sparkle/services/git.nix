{
  config,
  pkgs,
  ...
}: {
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
        "debian:docker://node:25"
      ];
      settings = {
        runner.capacity = 1;
        container = {
          network = "bridge";
          docker_host = "-";
          pull_policy = "always";
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
