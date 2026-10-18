{lib, ...}: {
  imports = [
    ../modules/shared/host.nix
    ../modules/shared/nix-settings.nix
    ../modules/nixos/system/console.nix
    ../modules/nixos/system/doas.nix
    ../modules/nixos/system/locale.nix
    ../modules/nixos/system/polkit-power.nix
    ../modules/nixos/system/security.nix
    ../modules/nixos/system/zram.nix
    ../modules/nixos/nix/nh.nix
    ../modules/nixos/networking/firewall.nix
    ../modules/nixos/networking/networkd.nix
    ../modules/nixos/services/chrony.nix
    ../modules/nixos/services/fwupd.nix
    ../modules/nixos/services/openssh.nix
    ../modules/nixos/programs/ghostty-terminfo.nix
    ../modules/nixos/programs/mtr.nix
    ../modules/nixos/programs/neovim.nix
    ../modules/nixos/programs/zsh.nix
  ];

  time.timeZone = lib.mkDefault "UTC";
}
