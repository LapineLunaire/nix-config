{lib, ...}: {
  imports = [
    ./database.nix
    ./ejabberd.nix
    ./fail2ban.nix
    ./proxy.nix
    ./tuwunel.nix
  ];

  # Disabled: sparxie is a VPS with no physical disks or firmware to manage.
  services.fwupd.enable = lib.mkForce false;
  services.smartd.enable = lib.mkForce false;
}
