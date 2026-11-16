{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../nixos.nix
    ../../modules/nixos/services/pipewire.nix
    ../../modules/nixos/services/smartd.nix
    ../../modules/nixos/system/zswap.nix
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/system-disks.nix
  ];

  time.timeZone = lib.mkDefault "Europe/Amsterdam";
  nixpkgs.overlays = with import ../../overlays; [additions modifications];
  console.keyMap = "colemak";
  nix.daemonCPUSchedPolicy = "idle";
  networking.networkmanager.enable = true;

  services.xserver.xkb = {
    layout = "us,us";
    variant = "colemak,";
    options = "grp:win_space_toggle";
  };

  hardware.graphics.enable = true;

  services.kmscon = {
    enable = true;
    config = {
      hwaccel = true;
      font-name = "JetBrainsMono Nerd Font";
      xkb-layout = "us";
      xkb-variant = "colemak";
    };
  };

  boot.plymouth.enable = true;
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "rd.udev.log_level=3"
  ];
  boot.loader.timeout = 0;

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
    enableNotifications = true;
  };

  programs.nix-ld.enable = true;
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = [pkgs.obs-studio-plugins.obs-pipewire-audio-capture];
  };

  services.pcscd.enable = true;
  services.smartd.notifications.systembus-notify.enable = true;
}
