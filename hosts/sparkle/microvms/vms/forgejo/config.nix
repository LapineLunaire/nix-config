{
  config,
  outputs,
  ...
}: let
  net = import ../../vm-net.nix;
  smtp = config.site.smtp;
in {
  imports = [
    ./sops.nix
    # Git-over-SSH on port 22 uses the system sshd; open it to git clients on the trusted subnets.
    outputs.nixosModules.trusted-ssh-ingress
  ];

  # Client subnets trusted to reach forgejo's git-ssh: LAN (10.28.64.0/24), WireGuard VPN (10.28.96.0/24), Nox's LAN (10.100.0.0/24), Nox's WireGuard (10.1.0.0/24).
  site.trustedSubnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];

  # The ProtonMail SMTP submission endpoint and the noreply relay account for forgejo's outgoing mail; the password secret lives in this VM's sops.
  site.smtp = {
    host = "smtp.protonmail.ch";
    port = "587";
    user = "noreply@lunaire.eu";
  };

  microvm = {
    vcpu = 2;
    mem = 1536;
    initialBalloonMem = 256;
  };

  sops.templates."forgejo.env".content = ''
    FORGEJO__mailer__PASSWD=${config.sops.placeholder."forgejo-smtp-password"}
  '';
  systemd.services.forgejo.serviceConfig.EnvironmentFile = config.sops.templates."forgejo.env".path;

  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      host = net.vmAddress.postgres;
      passwordFile = config.sops.secrets."forgejo-db-password".path;
      createDatabase = false;
    };
    settings = {
      security = {
        REVERSE_PROXY_LIMIT = 1;
        REVERSE_PROXY_TRUSTED_PROXIES = net.hostAddress;
      };
      server = {
        DOMAIN = "git.lunaire.moe";
        ROOT_URL = "https://git.lunaire.moe/";
        HTTP_PORT = 3000;
        SSH_DOMAIN = "git-ssh.lunaire.moe";
      };
      mailer = {
        ENABLED = true;
        SMTP_ADDR = smtp.host;
        SMTP_PORT = smtp.port;
        FROM = "Forgejo <${smtp.user}>";
        USER = smtp.user;
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

  microvmGuest.hostIngressTCPPorts = [3000];
}
