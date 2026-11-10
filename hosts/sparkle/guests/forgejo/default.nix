{
  config,
  pkgs,
  net,
  trustedSubnets,
  web,
  ...
}: {
  imports = [
    # Git over SSH uses the system sshd; open it to trusted subnets.
    ../../../../modules/nixos/networking/trusted-ssh-ingress.nix
    ./sops.nix
  ];

  host.trustedSubnets = trustedSubnets.all;

  # Also allow Uptime Kuma's SSH check.
  networking.firewall.extraInputRules = ''
    ip saddr ${net.vmAddress.uptime-kuma} tcp dport 22 accept
  '';

  microvm = {
    vcpu = 2;
    mem = 1536;
    initialBalloonMem = 256;
  };

  # Mirrors over SSH, HTTP and the git protocol, webhooks, and SMTP.
  microvmGuest.egress = [
    {
      proto = "tcp";
      ports = [22 80 443 587 9418];
    }
  ];

  services.forgejo = let
    inherit (config.host) smtp;
  in {
    enable = true;
    package = pkgs.forgejo;
    secrets.mailer.PASSWD = config.sops.secrets."forgejo-smtp-password".path;
    database = {
      type = "postgres";
      host = net.vmAddress.postgres;
      passwordFile = config.sops.secrets."forgejo-db-password".path;
      createDatabase = false;
    };
    settings = {
      security = {
        REVERSE_PROXY_LIMIT = 1;
        REVERSE_PROXY_TRUSTED_PROXIES = net.vmAddress.proxy;
      };
      server = {
        DOMAIN = web.vhost.forgejo;
        ROOT_URL = "${web.origin.forgejo}/";
        HTTP_PORT = web.endpoints.forgejo.port;
        SSH_DOMAIN = "git-ssh.${web.domain}";
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
      };
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
        ENDLESS_TASK_TIMEOUT = "6h";
      };
    };
  };
}
