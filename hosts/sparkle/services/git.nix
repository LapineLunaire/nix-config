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
      service.DISABLE_REGISTRATION = true;
      actions.ENABLED = true;
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "sparkle";
      url = "https://git.lunaire.moe";
      tokenFile = config.sops.templates."forgejo-runner-token.env".path;
      labels = ["native:host"];
      hostPackages = with pkgs; [
        bash
        coreutils
        curl
        gawk
        gitMinimal
        gnused
        nix
        nodejs
        wget
      ];
      settings.runner.capacity = 1;
    };
  };

  systemd.services.gitea-runner-default = {
    after = ["forgejo.service"];
    requires = ["forgejo.service"];
  };
}
