{lib, ...}: {
  imports = [
    ./conduit.nix
    ./proxy.nix
  ];

  services.smartd.enable = lib.mkForce false;
}
