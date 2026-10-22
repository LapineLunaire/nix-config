{pkgs, ...}: {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/system/secure-boot.nix
    ../../modules/nixos/system/tuned-kernel.nix
    ../../modules/nixos/programs/gaming.nix
    ../../modules/nixos/networking/steam-frame.nix
    ../../modules/nixos/nix/desktop-cache.nix
    ../../modules/nixos/networking/trusted-ssh-ingress.nix
    ../../modules/nixos/networking/wireless-regulatory-domain.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
    ./displays.nix
    ./pipewire.nix
    ./samba-mounts.nix
  ];

  networking.hostName = "camellya";

  host.flakePath = "/persist/nix-config";
  host.wirelessRegulatoryDomain = "NL";
  host.trustedSubnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];
  hardware.steamFrame.lanSubnets = ["10.28.64.0/24"];
  nixpkgs.config.allowUnfree = true;

  host.kernel = {
    packages = pkgs.linuxPackages_7_3;
    cpu = "znver5";
  };

  # Let CPPC manage frequency scaling.
  boot.kernelParams = ["amd_pstate=active"];

  powerManagement.cpuFreqGovernor = "powersave";

  # WinBox discovery (UDP 5678) is LAN-only.
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.64.0/24 udp dport 5678 accept
  '';

  services.udev.packages = [pkgs.wooting-udev-rules];

  services.xserver.videoDrivers = ["nvidia"];
  programs.obs-studio.package = pkgs.obs-studio.override {cudaSupport = true;};

  virtualisation.waydroid.enable = true;
  programs.anime-games-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;

  system.stateVersion = "26.11";
  home-manager.users.carmilla.home.stateVersion = "26.11";
}
