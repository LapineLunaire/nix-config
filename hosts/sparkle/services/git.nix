{...}: {
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
}
