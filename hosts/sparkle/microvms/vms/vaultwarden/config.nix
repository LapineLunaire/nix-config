{config, ...}: let
  net = import ../../vm-net.nix;
  smtp = config.site.smtp;
in {
  imports = [./sops.nix];

  # The ProtonMail SMTP submission endpoint and the noreply relay account for vaultwarden's outgoing mail; the password secret lives in this VM's sops.
  site.smtp = {
    host = "smtp.protonmail.ch";
    port = "587";
    user = "noreply@lunaire.eu";
  };

  microvm = {
    vcpu = 1;
    mem = 768;
    initialBalloonMem = 256;
  };

  sops.templates."vaultwarden.env".content = ''
    ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}
    DATABASE_URL=postgresql://vaultwarden:${config.sops.placeholder."vaultwarden-db-password"}@${net.vmAddress.postgres}/vaultwarden
    SMTP_HOST=${smtp.host}
    SMTP_PORT=${smtp.port}
    SMTP_SECURITY=starttls
    SMTP_FROM=${smtp.user}
    SMTP_FROM_NAME=Vaultwarden
    SMTP_USERNAME=${smtp.user}
    SMTP_PASSWORD=${config.sops.placeholder."vaultwarden-smtp-password"}
  '';

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = config.sops.templates."vaultwarden.env".path;
    config = {
      DOMAIN = "https://vw.lunaire.moe";
      ROCKET_ADDRESS = net.vmAddress.vaultwarden;
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
    };
  };

  microvmGuest.hostIngressTCPPorts = [8222];
}
