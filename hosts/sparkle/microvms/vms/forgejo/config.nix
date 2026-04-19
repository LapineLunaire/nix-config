{config, ...}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 1536;
    initialBalloonMem = 256;
    vsock.cid = 12;
    interfaces = [
      {
        type = "tap";
        id = "forgejo";
        mac = "02:00:00:00:00:12";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/forgejo";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };
  networking.hostName = "forgejo";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.12";
      prefixLength = 24;
    }
  ];

  sops.templates."forgejo.env".content = ''
    FORGEJO__mailer__PASSWD=${config.sops.placeholder."forgejo-smtp-password"}
  '';
  systemd.services.forgejo.serviceConfig.EnvironmentFile = config.sops.templates."forgejo.env".path;

  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      host = "10.28.34.10";
      passwordFile = config.sops.secrets."forgejo-db-password".path;
      createDatabase = false;
    };
    settings = {
      security = {
        REVERSE_PROXY_LIMIT = 1;
        REVERSE_PROXY_TRUSTED_PROXIES = "10.28.34.1";
      };
      server = {
        DOMAIN = "git.lunaire.moe";
        ROOT_URL = "https://git.lunaire.moe/";
        HTTP_PORT = 3000;
        SSH_DOMAIN = "git-ssh.lunaire.moe";
      };
      mailer = {
        ENABLED = true;
        SMTP_ADDR = "smtp.protonmail.ch";
        SMTP_PORT = 587;
        FROM = "Forgejo <noreply@lunaire.eu>";
        USER = "noreply@lunaire.eu";
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

  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 3000 accept
    ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 22 accept
  '';
}
