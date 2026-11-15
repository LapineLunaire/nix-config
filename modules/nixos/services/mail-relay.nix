{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.host) smtp;
in {
  imports = [../../shared/host.nix];

  options.host = {
    sendAlert = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = pkgs.writeShellScript "send-alert" ''
        set -euo pipefail
        {
          printf 'Subject: %s: %s\n\n' ${lib.escapeShellArg config.networking.hostName} "$1"
          ${pkgs.coreutils}/bin/cat
        } | ${config.programs.msmtp.package}/bin/sendmail ${lib.escapeShellArg config.host.alertEmail}
      '';
      description = "Command that mails its standard input to host.alertEmail, with the host name and its argument as the subject.";
    };

    mailOnFailure = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Units whose last 50 journal lines are mailed when they fail, each mapped to the mail subject.";
    };
  };

  config = {
    sops.secrets.${smtp.passwordSecret} = {};

    programs.msmtp = {
      enable = true;
      setSendmail = true;
      accounts.default = {
        inherit (smtp) host port user;
        auth = true;
        tls = true;
        from = smtp.user;
        passwordeval = "cat ${config.sops.secrets.${smtp.passwordSecret}.path}";
      };
    };

    systemd.services = lib.mkMerge (lib.mapAttrsToList (unit: subject: {
        ${unit}.onFailure = ["${unit}-failed.service"];
        "${unit}-failed" = {
          description = "Mail the last 50 journal lines of ${unit}";
          serviceConfig.Type = "oneshot";
          script = ''
            set -euo pipefail
            ${config.systemd.package}/bin/journalctl -u ${lib.escapeShellArg unit} -n 50 --no-pager | ${config.host.sendAlert} ${lib.escapeShellArg subject}
          '';
        };
      })
      config.host.mailOnFailure);
  };
}
