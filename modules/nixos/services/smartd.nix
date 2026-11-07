{
  config,
  lib,
  pkgs,
  ...
}: {
  services.smartd.enable = true;
  # Systems with the mail relay mail disk warnings.
  services.smartd.notifications.mail = lib.mkIf config.programs.msmtp.enable {
    enable = true;
    sender = config.host.smtp.user;
    recipient = config.host.alertEmail;
  };
  environment.systemPackages = [pkgs.smartmontools];
}
