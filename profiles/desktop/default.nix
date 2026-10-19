{lib, ...}: {
  imports = [
    ../../modules/shared/host.nix
    ../../modules/shared/nix-settings.nix
    ../../modules/nixos/system/console.nix
    ../../modules/nixos/system/doas.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/polkit-power.nix
    ../../modules/nixos/system/security.nix
    ../../modules/nixos/system/zram.nix
    ../../modules/nixos/nix/nh.nix
    ../../modules/nixos/networking/firewall.nix
    ../../modules/nixos/services/chrony.nix
    ../../modules/nixos/services/earlyoom.nix
    ../../modules/nixos/services/kmscon.nix
    ../../modules/nixos/services/openssh.nix
    ../../modules/nixos/services/pipewire.nix
    ../../modules/nixos/services/smartd.nix
    ../../modules/nixos/programs/ghostty-terminfo.nix
    ../../modules/nixos/programs/neovim.nix
    ../../modules/nixos/programs/obs-studio.nix
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/system-disks.nix
    ../../modules/nixos/desktop/xkb.nix
  ];

  time.timeZone = lib.mkDefault "Europe/Amsterdam";
  nixpkgs.overlays = [(import ../../overlays.nix).modifications];
  console.keyMap = "colemak";
  nix.daemonCPUSchedPolicy = "idle";
  networking.networkmanager.enable = true;

  programs.nix-ld.enable = true;
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  services.pcscd.enable = true;
  services.fwupd.enable = true;
  services.smartd.notifications.systembus-notify.enable = true;
  programs.mtr.enable = true;
  programs.zsh.enable = true;
}
