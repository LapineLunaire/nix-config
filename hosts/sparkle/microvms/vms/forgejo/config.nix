{config, ...}: let
  net = import ../../vm-net.nix;
  smtp = import ../../../../../modules/nixos/protonmail-smtp.nix;
in {
  imports = [./sops.nix];

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

  # Git-over-SSH on port 22 uses the system sshd; open it to git clients on the trusted subnets.
  networking.firewall.extraInputRules = ''
    ip saddr { ${(import ../../../../../modules/nixos/trusted-subnets.nix).nftSet} } tcp dport 22 accept
  '';
  microvmGuest.hostIngressTCPPorts = [3000];
}
