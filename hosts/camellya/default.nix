{
  lib,
  pkgs,
  ...
}: let
  trustedSubnets = import ../trusted-subnets.nix;
in {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/system/secure-boot.nix
    ../../modules/nixos/system/tuned-kernel.nix
    ../../modules/nixos/services/btrfs.nix
    ../../modules/nixos/programs/gaming.nix
    ../../modules/nixos/networking/steam-frame.nix
    ../../modules/nixos/nix/desktop-cache.nix
    ../../modules/nixos/networking/trusted-ssh-ingress.nix
    ../../modules/nixos/networking/wireless-regulatory-domain.nix
    ./hardware-configuration.nix
    ../../modules/nixos/system/persistence.nix
    ./sops.nix
    ./displays.nix
    ./pipewire.nix
    ./samba-mounts.nix
  ];

  networking.hostName = "camellya";

  host.flakePath = "/persist/nix-config";
  host.swapFileSize = 16;
  host.wirelessRegulatoryDomain = "NL";
  host.trustedSubnets = trustedSubnets.all;
  hardware.steamFrame.lanSubnets = [trustedSubnets.lan];

  host.kernel = {
    packages = pkgs.linuxPackages_7_3;
    cpu = "znver5";
  };

  # Let CPPC manage frequency scaling.
  boot.kernelParams = ["amd_pstate=active"];

  powerManagement.cpuFreqGovernor = "powersave";

  # WinBox discovery is LAN-only.
  networking.firewall.extraInputRules = ''
    ip saddr ${trustedSubnets.lan} udp dport 5678 accept
  '';

  services.udev.packages = [pkgs.wooting-udev-rules];

  services.xserver.videoDrivers = ["nvidia"];
  programs.obs-studio.package = pkgs.obs-studio.override {cudaSupport = true;};

  virtualisation.waydroid.enable = true;
  # The Waydroid module trusts its whole bridge. Android only needs the host's DNS and DHCP.
  networking.firewall.trustedInterfaces = lib.mkForce ["lo"];
  networking.firewall.interfaces.waydroid0 = {
    allowedTCPPorts = [53 67];
    allowedUDPPorts = [53 67];
  };
  programs.anime-games-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;

  system.stateVersion = "26.11";
  home-manager.users.carmilla.home.stateVersion = "26.11";
}
