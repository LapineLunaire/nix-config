{pkgs, ...}: {
  imports = [
    ../generic
    ../../users/lapine.nix
    ./hardware-configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    # zfs_unstable for newer kernel compatibility
    zfs.package = pkgs.zfs_unstable;
  };

  networking = {
    hostName = "sampo";
    # hostId is required for ZFS
    hostId = "0390c0e9";
    networkmanager.enable = true;
  };

  # Persist system state across reboots (root is tmpfs)
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/NetworkManager"
      "/var/log"
      "/etc/ssh"
    ];
    files = [
      "/etc/machine-id"
      "/etc/shadow"
      "/etc/nixos"
    ];
  };

  system.stateVersion = "25.11";
}
