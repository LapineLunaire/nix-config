# Borg backup to the Hetzner Storage Box from a ZFS snapshot of <pool>/persist. Import as (import ./borg-backup.nix { pool = "tank"; startAt = "02:30"; }).
{
  pool,
  startAt,
}: {
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    "borg-passphrase" = {};
    "borg-ssh-key" = {};
    "borg-repo" = {};
    # Full known_hosts line for the storage box. Get it with: ssh-keyscan -p 23 <hostname>
    "borg-known-hosts" = {};
  };

  services.borgbackup.jobs.hetzner = {
    repo = "unset"; # actual repo URL injected via BORG_REPO in preHook
    paths = ["/mnt/borg-snapshot"];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg-passphrase".path}";
    };
    environment.BORG_RSH = "ssh -i ${config.sops.secrets."borg-ssh-key".path} -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${config.sops.secrets."borg-known-hosts".path}";
    compression = "auto,zstd";
    inherit startAt;
    preHook = ''
      export BORG_REPO=$(< ${config.sops.secrets."borg-repo".path})
      # Unmount any snapshot left behind by an interrupted run; a mounted snapshot makes the destroy below fail and the snapshot create abort on the leftover.
      ${pkgs.util-linux}/bin/umount /mnt/borg-snapshot 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs destroy ${pool}/persist@borg-backup 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs snapshot ${pool}/persist@borg-backup
      ${pkgs.coreutils}/bin/mkdir -p /mnt/borg-snapshot
      ${pkgs.util-linux}/bin/mount -t zfs ${pool}/persist@borg-backup /mnt/borg-snapshot
    '';
    postHook = ''
      ${pkgs.util-linux}/bin/umount /mnt/borg-snapshot 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs destroy ${pool}/persist@borg-backup 2>/dev/null || true
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
