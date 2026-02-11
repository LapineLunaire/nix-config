{lib, ...}: {
  services.smartd.enable = lib.mkForce false;
}
