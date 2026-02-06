{...}: {
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DOMAIN = "https://vw.lunaire.moe";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 6000;
      SIGNUPS_ALLOWED = false;
      DATABASE_URL = "postgresql://vaultwarden@/vaultwarden";
    };
  };
}
