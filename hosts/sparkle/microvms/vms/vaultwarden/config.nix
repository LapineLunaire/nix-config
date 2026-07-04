{config, ...}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix];

  microvm = {
    vcpu = 1;
    mem = 768;
    initialBalloonMem = 256;
  };

  sops.templates."vaultwarden.env".content = ''
    ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}
    DATABASE_URL=postgresql://vaultwarden:${config.sops.placeholder."vaultwarden-db-password"}@${net.ip.postgres}/vaultwarden
    SMTP_HOST=smtp.protonmail.ch
    SMTP_PORT=587
    SMTP_SECURITY=starttls
    SMTP_FROM=noreply@lunaire.eu
    SMTP_FROM_NAME=Vaultwarden
    SMTP_USERNAME=noreply@lunaire.eu
    SMTP_PASSWORD=${config.sops.placeholder."vaultwarden-smtp-password"}
  '';

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = config.sops.templates."vaultwarden.env".path;
    config = {
      DOMAIN = "https://vw.lunaire.moe";
      ROCKET_ADDRESS = net.ip.vaultwarden;
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
    };
  };

  microvmGuest.hostIngressTCPPorts = [8222];
}
