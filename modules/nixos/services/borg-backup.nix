{
  config,
  lib,
  pkgs,
  ...
}: let
  dataset = config.fileSystems."/persist".device;
  job = config.services.borgbackup.jobs.hetzner;
  zfs = lib.getExe config.boot.zfs.package;
  loadRepository = ''
    BORG_REPO=$(< ${config.sops.secrets."borg-repo".path})
    : "''${BORG_REPO:?Borg repository secret is empty}"
    export BORG_REPO
  '';
  lastSuccess = "/var/lib/borgbackup/hetzner/last-success";
in {
  imports = [./mail-relay.nix];

  assertions = [
    {
      assertion = config.fileSystems."/persist".fsType == "zfs";
      message = "Borg snapshot backups require /persist to use ZFS.";
    }
  ];

  sops.secrets = {
    "borg-passphrase" = {};
    "borg-ssh-key" = {};
    "borg-repo" = {};
    # Full known_hosts line for the storage box, obtained with: ssh-keyscan -p 23 <hostname>
    "borg-known-hosts" = {};
  };

  services.borgbackup.jobs.hetzner = {
    # BORG_REPO supplies the runtime URL. A non-path placeholder avoids local-repository setup.
    repo = "unset";
    # borg-job-hetzner replaces the upstream wrapper, which cannot read the repository secret.
    wrapper = null;
    doInit = false;
    paths = ["/mnt/borg-snapshot"];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg-passphrase".path}";
    };
    environment.BORG_RSH = "ssh -i ${config.sops.secrets."borg-ssh-key".path} -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${config.sops.secrets."borg-known-hosts".path}";
    compression = "auto,zstd";
    # Exclude disposable guest disk images.
    exclude = ["pp:/mnt/borg-snapshot/volumes"];
    persistentTimer = true;
    preHook = ''
      while [ "$(${config.systemd.package}/bin/systemctl show -P ActiveState nixos-upgrade.service)" = activating ] || [ -e /run/systemd/shutdown/scheduled ]; do
        ${pkgs.coreutils}/bin/sleep 30
      done
      ${loadRepository}
      # Recover the mount and snapshot left by an interrupted backup.
      ${pkgs.util-linux}/bin/umount /mnt/borg-snapshot 2>/dev/null || true
      ${zfs} destroy ${dataset}@borg-backup 2>/dev/null || true
      ${zfs} snapshot ${dataset}@borg-backup
      ${pkgs.coreutils}/bin/mkdir -p /mnt/borg-snapshot
      ${pkgs.util-linux}/bin/mount -t zfs ${dataset}@borg-backup /mnt/borg-snapshot
    '';
    postHook = ''
      ${pkgs.util-linux}/bin/umount /mnt/borg-snapshot 2>/dev/null || true
      ${zfs} destroy ${dataset}@borg-backup 2>/dev/null || true
    '';
    # The script's last step, reached only after every Borg command succeeds.
    postPrune = ''
      if [ "$(${pkgs.coreutils}/bin/date +%d)" = 01 ]; then
        borgWrapper check --repository-only
      fi
      ${pkgs.coreutils}/bin/touch ${lastSuccess}
    '';
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 3;
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "borg-job-hetzner" ''
      set -euo pipefail
      ${loadRepository}
      export BORG_PASSCOMMAND=${lib.escapeShellArg job.encryption.passCommand}
      export BORG_RSH=${lib.escapeShellArg job.environment.BORG_RSH}
      exec ${lib.getExe config.services.borgbackup.package} "$@"
    '')
  ];

  # ReadWritePaths must exist before the service namespace and preHook are set up.
  systemd.tmpfiles.settings."10-borg-backup"."/mnt".d = {
    user = "root";
    group = "root";
    mode = "0755";
  };

  systemd.services."borgbackup-job-hetzner" = {
    onFailure = ["borgbackup-failed.service"];
    # Restarting a waiting backup during an upgrade's switch would deadlock.
    restartIfChanged = false;
    serviceConfig = {
      # nixos-upgrade's ordering only waits for a backup that runs as a oneshot.
      Type = "oneshot";
      ReadWritePaths = ["/mnt"];
      StateDirectory = "borgbackup/hetzner";
    };
  };

  systemd.services.nixos-upgrade.after = lib.mkIf config.system.autoUpgrade.enable ["borgbackup-job-hetzner.service"];

  systemd.services.borgbackup-failed = {
    description = "Mail the failed Borg backup log";
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      {
        printf 'Subject: ${config.networking.hostName}: Borg backup failed\n\n'
        ${config.systemd.package}/bin/journalctl -u borgbackup-job-hetzner -n 50 --no-pager
      } | ${config.programs.msmtp.package}/bin/sendmail carmilla@lunaire.eu
    '';
  };

  # The failure hook cannot report a backup that never runs.
  systemd.services.borgbackup-freshness = {
    description = "Mail when no Borg backup succeeded in 24 hours";
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      if [[ -z "$(${pkgs.findutils}/bin/find ${lastSuccess} -mmin -1440 2>/dev/null)" ]]; then
        printf 'Subject: ${config.networking.hostName}: Borg backup overdue\n\nNo successful backup in the last 24 hours.\n' \
          | ${config.programs.msmtp.package}/bin/sendmail carmilla@lunaire.eu
      fi
    '';
  };

  systemd.timers.borgbackup-freshness = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "12:00";
      Persistent = true;
    };
  };
}
