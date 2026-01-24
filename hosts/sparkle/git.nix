{config, ...}: {
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
    };
  };

  systemd.tmpfiles.rules = [
    "d '${config.services.forgejo.stateDir}' 0750 ${config.services.forgejo.user} ${config.services.forgejo.group} - -"
    "d '${config.services.forgejo.customDir}' 0750 ${config.services.forgejo.user} ${config.services.forgejo.group} - -"
  ];
}
