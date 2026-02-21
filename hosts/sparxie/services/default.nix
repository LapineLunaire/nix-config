{lib, ...}: {
  imports = [
    ./database.nix
    ./ejabberd.nix
    ./proxy.nix
    ./tuwunel.nix
  ];

  services.fwupd.enable = lib.mkForce false;
  services.smartd.enable = lib.mkForce false;
}
