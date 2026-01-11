{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../generic
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
      "/var/log"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # /etc/nixos symlink to persisted config
  environment.etc."nixos".source = "/persist/nix-config";

  # Disable smartd (VM has no physical disks)
  services.smartd.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
