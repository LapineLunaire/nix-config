{lib, ...}: {
  imports = [
    ../nixos.nix
    ../../modules/nixos/system/zram.nix
  ];

  time.timeZone = lib.mkDefault "UTC";

  systemd.network.enable = lib.mkDefault true;
  # Otherwise dhcpcd runs next to networkd.
  networking.useDHCP = false;
}
