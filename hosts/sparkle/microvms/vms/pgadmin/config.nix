{config, ...}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix ../docker-common.nix];

  microvm = {
    vcpu = 1;
    mem = 1536;
    initialBalloonMem = 256;
    volumes = [
      {
        image = "/persist/vms/pgadmin/volumes/docker.img";
        mountPoint = "/var/lib/docker";
        size = 5120;
        fsType = "xfs";
      }
    ];
  };

  sops.templates."pgadmin.env".content = ''
    PGADMIN_DEFAULT_PASSWORD=${config.sops.placeholder."pgadmin-password"}
    PGADMIN_CONFIG_AUTHENTICATION_SOURCES=['oauth2']
    PGADMIN_CONFIG_OAUTH2_AUTO_CREATE_USER=True
    PGADMIN_CONFIG_OAUTH2_CONFIG=[{'OAUTH2_NAME': 'authelia', 'OAUTH2_DISPLAY_NAME': 'Lunaire SSO', 'OAUTH2_CLIENT_ID': 'pgadmin', 'OAUTH2_CLIENT_SECRET': '${config.sops.placeholder."pgadmin-oidc-client-secret"}', 'OAUTH2_SERVER_METADATA_URL': 'https://auth.lunaire.moe/.well-known/openid-configuration', 'OAUTH2_USERINFO_ENDPOINT': 'https://auth.lunaire.moe/api/oidc/userinfo', 'OAUTH2_SCOPE': 'openid email profile', 'OAUTH2_USERNAME_CLAIM': 'preferred_username'}]
  '';

  virtualisation.oci-containers.containers.pgadmin = {
    image = "dpage/pgadmin4@sha256:40fa840c5bb7c8463957f1255b01283732c2d8c9396a956d180f8e6c296753b3";
    autoStart = true;
    environment = {
      PGADMIN_DEFAULT_EMAIL = "lapine@lunaire.eu";
      PGADMIN_LISTEN_PORT = "5000";
    };
    environmentFiles = [config.sops.templates."pgadmin.env".path];
    volumes = ["/persist/var/lib/pgadmin:/var/lib/pgadmin"];
    ports = ["${net.vmAddress.pgadmin}:5000:5000"];
  };

  microvmGuest.hostIngressTCPPorts = [5000];
}
