# The ProtonMail SMTP submission endpoint and the noreply relay account, shared by sparkle's msmtp, smartd alerts, and the mail-sending VM services (authelia, forgejo, vaultwarden). Each consumer keeps its own copy of the password secret.
{
  host = "smtp.protonmail.ch";
  port = "587";
  user = "noreply@lunaire.eu";
}
