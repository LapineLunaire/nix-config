{pkgs, ...}: {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/system/secure-boot.nix
    ../../modules/nixos/system/tuned-kernel.nix
    ../../modules/nixos/programs/gaming.nix
    ../../modules/nixos/nix/desktop-cache.nix
    ../../modules/nixos/networking/trusted-ssh-ingress.nix
    ../../modules/nixos/networking/wireless-regulatory-domain.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
  ];

  networking.hostName = "kafka";

  host = {
    flakePath = "/persist/nix-config";
    wirelessRegulatoryDomain = "NL";
    trustedSubnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];
  };

  nixpkgs.config.allowUnfree = true;
  host.kernel = {
    packages = pkgs.linuxPackages_7_2;
    cpu = "tigerlake";
  };

  services.thermald.enable = true;
  hardware.bluetooth.enable = true;

  nix.settings = {
    max-jobs = 2;
    cores = 4;
    # Build on disk rather than in the laptop's limited tmpfs.
    build-dir = "/nix/var/nix/builds";
  };
  systemd.tmpfiles.rules = ["d /nix/var/nix/builds 0755 root root -"];

  system.stateVersion = "26.11";
  home-manager.users.carmilla.home.stateVersion = "26.11";
}
