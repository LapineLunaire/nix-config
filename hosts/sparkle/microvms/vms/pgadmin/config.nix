{config, ...}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 1;
    mem = 1536;
    initialBalloonMem = 256;
    vsock.cid = 20;
    interfaces = [
      {
        type = "tap";
        id = "pgadmin";
        mac = "02:00:00:00:00:20";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/pgadmin";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
    volumes = [
      {
        image = "/persist/vms/pgadmin/volumes/docker.img";
        mountPoint = "/var/lib/docker";
        size = 5120;
        fsType = "xfs";
      }
    ];
  };
  networking.hostName = "pgadmin";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.20";
      prefixLength = 24;
    }
  ];

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  sops.templates."pgadmin.env".content = ''
    PGADMIN_DEFAULT_PASSWORD=${config.sops.placeholder."pgadmin-password"}
    PGADMIN_CONFIG_AUTHENTICATION_SOURCES=['oauth2']
    PGADMIN_CONFIG_OAUTH2_AUTO_CREATE_USER=True
    PGADMIN_CONFIG_OAUTH2_CONFIG=[{'OAUTH2_NAME': 'authelia', 'OAUTH2_DISPLAY_NAME': 'Lunaire SSO', 'OAUTH2_CLIENT_ID': 'pgadmin', 'OAUTH2_CLIENT_SECRET': '${config.sops.placeholder."pgadmin-oidc-client-secret"}', 'OAUTH2_SERVER_METADATA_URL': 'https://auth.lunaire.moe/.well-known/openid-configuration', 'OAUTH2_USERINFO_ENDPOINT': 'https://auth.lunaire.moe/api/oidc/userinfo', 'OAUTH2_SCOPE': 'openid email profile', 'OAUTH2_USERNAME_CLAIM': 'preferred_username'}]
  '';

  virtualisation.oci-containers.containers.pgadmin = {
    image = "dpage/pgadmin4@sha256:ff557f69d9808085dc3554f56c1b06a36ac8cddabe4485212920b9604261abdb";
    autoStart = true;
    environment = {
      PGADMIN_DEFAULT_EMAIL = "lapine@lunaire.eu";
      PGADMIN_LISTEN_PORT = "5000";
    };
    environmentFiles = [config.sops.templates."pgadmin.env".path];
    volumes = ["/persist/var/lib/pgadmin:/var/lib/pgadmin"];
    ports = ["10.28.34.20:5000:5000"];
  };

  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 5000 accept
  '';
}
