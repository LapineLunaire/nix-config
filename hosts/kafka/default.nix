{pkgs, ...}: {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/system/secure-boot.nix
    ../../modules/nixos/system/tuned-kernel.nix
    ../../modules/nixos/services/btrfs.nix
    ../../modules/nixos/programs/gaming.nix
    ../../modules/nixos/nix/attic-client.nix
    ../../modules/nixos/networking/trusted-ssh-ingress.nix
    ../../modules/nixos/networking/trusted-connections.nix
    ../../modules/nixos/networking/wireless-regulatory-domain.nix
    ../../modules/nixos/system/tmpfs-root.nix
    ./hardware-configuration.nix
    ../../modules/nixos/system/persistence.nix
  ];

  networking.hostName = "kafka";

  host = {
    # 16 GiB of RAM is not enough for parallel Nix builds.
    swapFileSize = 32;
    wirelessRegulatoryDomain = "NL";
    trustedConnections = [
      "ea502939-2dee-417c-929e-6bd1a1c7b794"
      "6949919a-dabb-4937-9737-e60014ff13c8"
    ];
  };

  host.kernel = {
    packages = pkgs.linuxPackages_7_3;
    cpu = "tigerlake";
  };

  services.thermald.enable = true;
  hardware.bluetooth.enable = true;

  nix.settings = {
    max-jobs = 2;
    cores = 4;
  };

  system.stateVersion = "26.11";

  home-manager.users.carmilla = {
    home.stateVersion = "26.11";

    programs.plasma = {
      workspace.wallpaper = "${../../users/carmilla/wallpapers/__trailblazer_stelle_and_kafka_honkai_and_1_more_drawn_by_rafaelaaa__70a37251632a5d567b2ea3e907c27cfb.jpg}";
      kscreenlocker.appearance.wallpaper = "${../../users/carmilla/wallpapers/__kafka_silver_wolf_and_blade_honkai_and_1_more_drawn_by_eiryu33__33516ee718464cde3c995ff00a7f9275.png}";
    };
  };
}
