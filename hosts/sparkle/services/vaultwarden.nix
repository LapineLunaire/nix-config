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
      # Generate with: vaultwarden hash
      ADMIN_TOKEN = "$argon2id$v=19$m=65540,t=3,p=4$JptV30FnYD5j6JifJnQvAi6L788zr6ZSY0XY2/X9miU$HMFFns8fg7aEx2fcZ/vNl79gaXQq9a8OAgRcV8v3X+U";
    };
  };
}
