{pkgs, ...}: let
  dmz = import ./dmz-net.nix;
in {
  imports = [
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/system/secure-boot.nix
    ../../modules/nixos/system/tuned-kernel.nix
    ../../modules/nixos/services/zfs.nix
    ../../modules/nixos/networking/trusted-ssh-ingress.nix
    ../../modules/nixos/services/mail-relay.nix
    ../../modules/nixos/services/borg-backup.nix
    ../../modules/nixos/microvm/host.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
    ./dmz-bridge.nix
    ../../modules/nixos/nix/server-cache.nix
    ./auto-update.nix
    ./telemetry.nix
  ];

  host.trustedSubnets = (import ./trusted-subnets.nix).all;

  host.flakePath = "/persist/nix-config";
  host.smtp.passwordSecret = "smtp-password";
  host.kernel = {
    packages = pkgs.linuxPackages_6_18;
    cpu = "alderlake";
  };

  nixpkgs.config.allowUnfree = true;

  services.borgbackup.jobs.hetzner.startAt = "03:00";

  networking = let
    net = import ./guest-net.nix;
  in {
    hostName = "sparkle";
    hostId = "d38a0d1c";
    # Use the DNS guest as systemd-resolved's upstream.
    nameservers = [net.vmAddress.dns];
  };

  # sops.nix assigns these names. Only sfp0 joins the DMZ bridge.
  systemd.network.networks = {
    "10-sfp0" = {
      matchConfig.Name = "sfp0";
      networkConfig = {
        DHCP = "no";
        Bridge = dmz.bridge;
      };
    };
    "10-sfp1" = {
      matchConfig.Name = "sfp1";
      linkConfig.Unmanaged = true;
    };
    "99-ipmi0" = {
      matchConfig.Name = "ipmi0";
      # The BMC manages its own network configuration.
      linkConfig.Unmanaged = true;
    };
  };

  # Leave the Zigbee controller and SAS HBA for their guests.
  boot.blacklistedKernelModules = ["cp210x" "mpt3sas"];

  boot = {
    kernelParams = [
      "intel_pstate=active"
      "intel_iommu=on"
      "iommu=pt"
    ];
    # Update ZFS and the kernel together.
    zfs.package = pkgs.zfs_2_4;
  };

  # HWP firmware controls frequency scaling in powersave mode.
  powerManagement.cpuFreqGovernor = "powersave";

  system.stateVersion = "26.05";
  home-manager.users.carmilla.home.stateVersion = "26.05";
}
