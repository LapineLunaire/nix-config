{config, ...}: {
  # Secrets that cannot be expressed as module options are injected via a
  # settings overlay file that Authelia merges at startup.
  sops.templates."authelia.yaml" = {
    content = ''
      storage:
        postgres:
          password: '${config.sops.placeholder."authelia-db-password"}'
      notifier:
        smtp:
          password: '${config.sops.placeholder."authelia-smtp-password"}'
    '';
    owner = "authelia-main";
  };

  services.authelia.instances.main = {
    enable = true;
    settingsFiles = [config.sops.templates."authelia.yaml".path];
    secrets = {
      jwtSecretFile = config.sops.secrets."authelia-jwt-secret".path;
      sessionSecretFile = config.sops.secrets."authelia-session-secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia-storage-encryption-key".path;
    };
    settings = {
      theme = "dark";
      log.level = "info";
      server.address = "tcp://127.0.0.1:2000/";
      session.cookies = [
        {
          domain = "lunaire.moe";
          authelia_url = "https://auth.lunaire.moe";
        }
      ];
      storage.postgres = {
        address = "tcp://localhost:5432";
        database = "authelia";
        username = "authelia";
      };
      authentication_backend.file.path = config.sops.secrets."authelia-users".path;
      webauthn = {
        disable = false;
        display_name = "Lunaire Auth";
        attestation_conveyance_preference = "indirect";
        user_verification = "preferred";
        timeout = "60s";
      };
      access_control.default_policy = "two_factor";
      notifier.smtp = {
        address = "smtp://smtp.protonmail.ch:587";
        username = "noreply@lunaire.eu";
        sender = "Authelia <noreply@lunaire.eu>";
      };
    };
  };
}
