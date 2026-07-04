{lib, ...}: {
  imports = [
    (import ../../../modules/nixos/borg-backup.nix {
      pool = "sparxie";
      startAt = "03:00";
    })
    ../../../modules/nixos/zfs-maintenance.nix
    ./database.nix
    ./ejabberd.nix
    ./fail2ban.nix
    ./proxy.nix
    ./tuwunel.nix
    ./wireguard.nix
  ];

  # Disabled: sparxie is a VPS with no physical disks or firmware to manage.
  services.fwupd.enable = lib.mkForce false;
  services.smartd.enable = lib.mkForce false;
}
