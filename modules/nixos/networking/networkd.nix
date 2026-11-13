{lib, ...}: {
  systemd.network.enable = lib.mkDefault true;

  # Otherwise dhcpcd runs next to networkd.
  networking.useDHCP = false;
}
