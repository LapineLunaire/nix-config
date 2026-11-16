{lib, ...}: {
  imports = [
    ../nixos.nix
    ../../modules/nixos/system/zram.nix
  ];

  time.timeZone = lib.mkDefault "UTC";
  nixpkgs.overlays = [(import ../../overlays).additions];

  systemd.network.enable = lib.mkDefault true;
  # Otherwise dhcpcd runs next to networkd.
  networking.useDHCP = false;
}
