# Applies the sops-templated pg-passwords.sql after postgres starts, since ensureUsers creates roles without passwords. The importing host defines the template's ALTER USER content.
{config, ...}: {
  systemd.services.postgresql-passwords = {
    description = "Set PostgreSQL user passwords from sops secrets";
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = "${config.services.postgresql.package}/bin/psql -f ${config.sops.templates."pg-passwords.sql".path}";
    };
  };
}
