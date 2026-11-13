{lib, ...}: {
  imports = [
    ../nixos.nix
    ../../modules/nixos/system/zram.nix
    ../../modules/nixos/networking/networkd.nix
  ];

  time.timeZone = lib.mkDefault "UTC";
  nixpkgs.overlays = [(import ../../overlays).additions];
}
