{lib, ...}: {
  imports = [
    ./database.nix
    ./ejabberd.nix
    ./proxy.nix
    ./tuwunel.nix
  ];

  services.smartd.enable = lib.mkForce false;
}
