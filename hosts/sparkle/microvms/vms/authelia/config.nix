{config, ...}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 1;
    mem = 768;
    initialBalloonMem = 256;
    vsock.cid = 11;
    interfaces = [
      {
        type = "tap";
        id = "authelia";
        mac = "02:00:00:00:00:11";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/authelia";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };
  networking.hostName = "authelia";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.11";
      prefixLength = 24;
    }
  ];

  sops.templates."authelia.yaml".content = ''
    storage:
      postgres:
        password: '${config.sops.placeholder."authelia-db-password"}'
    session:
      redis:
        password: '${config.sops.placeholder."redis-authelia-password"}'
    notifier:
      smtp:
        password: '${config.sops.placeholder."authelia-smtp-password"}'
    identity_providers:
      oidc:
        clients:
          - client_id: forgejo
            client_name: Forgejo
            client_secret: '${config.sops.placeholder."authelia-forgejo-client-secret-hash"}'
            public: false
            authorization_policy: two_factor
            redirect_uris:
              - https://git.lunaire.moe/user/oauth2/authelia/callback
            scopes:
              - openid
              - profile
              - email
              - groups
            userinfo_signed_response_alg: none
            grant_types:
              - authorization_code
            response_types:
              - code
          - client_id: pgadmin
            client_name: pgAdmin
            client_secret: '${config.sops.placeholder."pgadmin-oidc-client-secret-hash"}'
            public: false
            authorization_policy: two_factor
            redirect_uris:
              - https://pga.lunaire.moe/oauth2/authorize
            scopes:
              - openid
              - profile
              - email
            userinfo_signed_response_alg: none
            grant_types:
              - authorization_code
            response_types:
              - code
  '';

  services.redis.servers.authelia = {
    enable = true;
    bind = "127.0.0.1";
    port = 6380;
    requirePassFile = config.sops.secrets."redis-authelia-password".path;
  };

  services.authelia.instances.main = {
    enable = true;
    settingsFiles = [config.sops.templates."authelia.yaml".path];
    secrets = {
      jwtSecretFile = config.sops.secrets."authelia-jwt-secret".path;
      sessionSecretFile = config.sops.secrets."authelia-session-secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia-storage-encryption-key".path;
      oidcHmacSecretFile = config.sops.secrets."authelia-oidc-hmac-secret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."authelia-oidc-issuer-key".path;
    };
    settings = {
      theme = "dark";
      log.level = "info";
      server.address = "tcp://10.28.34.11:9091/";
      session = {
        redis = {
          host = "127.0.0.1";
          port = 6380;
        };
        cookies = [
          {
            domain = "lunaire.moe";
            authelia_url = "https://auth.lunaire.moe";
          }
        ];
      };
      storage.postgres = {
        address = "tcp://10.28.34.10:5432";
        database = "authelia";
        username = "authelia";
      };
      authentication_backend.file.path = config.sops.secrets."authelia-users".path;
      webauthn = {
        disable = false;
        display_name = "Lunaire Auth";
        attestation_conveyance_preference = "indirect";
        selection_criteria.user_verification = "preferred";
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

  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 9091 accept
  '';
}
