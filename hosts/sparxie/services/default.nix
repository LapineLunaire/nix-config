{
  lib,
  outputs,
  ...
}: {
  imports = [
    (import outputs.nixosModules.borg-backup {
      pool = "sparxie";
      startAt = "03:00";
    })
    outputs.nixosModules.zfs-maintenance
    outputs.nixosModules.caddy
    ./database.nix
    ./ejabberd.nix
    ./fail2ban.nix
    ./proxy.nix
    ./tuwunel.nix
    ./wireguard.nix
  ];

  # Disabled: sparxie is a VPS with no firmware to manage.
  services.fwupd.enable = lib.mkForce false;
}
