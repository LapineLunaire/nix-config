{
  config,
  pkgs,
  ...
}: {
  services.borgbackup.jobs.hetzner = {
    repo = "unset"; # actual repo URL injected via BORG_REPO in preHook
    paths = ["/mnt/borg-snapshot"];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg-passphrase".path}";
    };
    environment.BORG_RSH = "ssh -i ${config.sops.secrets."borg-ssh-key".path} -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${config.sops.templates."borg-known-hosts".path}";
    compression = "auto,zstd";
    startAt = "03:00";
    preHook = ''
      export BORG_REPO=$(< ${config.sops.secrets."borg-repo".path})
      ${pkgs.zfs}/bin/zfs destroy sparxie/persist@borg-backup 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs snapshot sparxie/persist@borg-backup
      ${pkgs.coreutils}/bin/mkdir -p /mnt/borg-snapshot
      ${pkgs.util-linux}/bin/mount -t zfs sparxie/persist@borg-backup /mnt/borg-snapshot
    '';
    postHook = ''
      ${pkgs.util-linux}/bin/umount /mnt/borg-snapshot 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs destroy sparxie/persist@borg-backup 2>/dev/null || true
    '';
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 3;
    };
  };

  systemd.services."borgbackup-job-hetzner".serviceConfig = {
    ReadWritePaths = ["/mnt"];
  };
}
