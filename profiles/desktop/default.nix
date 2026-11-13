{lib, ...}: {
  imports = [
    ../nixos.nix
    ../../modules/nixos/services/earlyoom.nix
    ../../modules/nixos/services/kmscon.nix
    ../../modules/nixos/services/pipewire.nix
    ../../modules/nixos/services/smartd.nix
    ../../modules/nixos/system/zswap.nix
    ../../modules/nixos/programs/obs-studio.nix
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/plymouth.nix
    ../../modules/nixos/desktop/system-disks.nix
    ../../modules/nixos/desktop/xkb.nix
  ];

  time.timeZone = lib.mkDefault "Europe/Amsterdam";
  nixpkgs.overlays = with import ../../overlays; [additions modifications];
  console.keyMap = "colemak";
  nix.daemonCPUSchedPolicy = "idle";
  networking.networkmanager.enable = true;

  programs.nix-ld.enable = true;
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  services.pcscd.enable = true;
  services.smartd.notifications.systembus-notify.enable = true;
}
