{lib, ...}: {
  imports = [
    ./tuwunel.nix
    ./proxy.nix
  ];

  services.smartd.enable = lib.mkForce false;
}
