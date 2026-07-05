# CIFS mounts of sparkle's samba shares, authenticated via the sops-rendered samba-credentials file. Mounted on first access (noauto + x-systemd.automount) and unmounted after 60s idle. Kept out of hardware-configuration.nix so regenerating it does not drop them.
{config, ...}: {
  fileSystems =
    builtins.mapAttrs (_: share: {
      device = "//sparkle.lunaire.moe/${share}";
      fsType = "cifs";
      options = [
        "credentials=${config.sops.templates."samba-credentials".path}"
        "uid=1000"
        "gid=100"
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
      ];
    }) {
      "/home/carmilla/vault" = "carmilla";
      "/home/carmilla/torrents" = "torrents";
    };
}
