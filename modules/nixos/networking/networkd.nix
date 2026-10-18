{lib, ...}: {
  systemd.network.enable = lib.mkDefault true;

  # Avoid networkd's catch-all DHCP configuration on unconfigured interfaces.
  networking.useDHCP = false;
}
