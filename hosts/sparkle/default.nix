{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nixos/generic
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./services
    ./microvms
  ];

  secureboot.enable = true;

  networking = {
    hostName = "sparkle";
    hostId = "d38a0d1c";
    # systemd-resolved intercepts DNS and breaks CoreDNS. Disable it and point
    # resolv.conf directly at the local CoreDNS instance instead.
    nameservers = ["10.28.32.25"];
  };

  services.resolved.enable = false;

  # Interface names (sfp0, sfp1, ipmi0) are assigned by sops-rendered .link files
  # in /etc/systemd/network/ based on MAC addresses. sfp0 is the primary uplink
  # with a static IP; sfp1 and ipmi0 are left unmanaged.
  systemd.network.networks = {
    "10-sfp0" = {
      matchConfig.Name = "sfp0";
      networkConfig = {
        DHCP = "no";
        Address = "10.28.32.25/23";
        Gateway = "10.28.32.1";
      };
    };
    "10-sfp1" = {
      matchConfig.Name = "sfp1";
      linkConfig.Unmanaged = true;
    };
    "99-ipmi0" = {
      matchConfig.Name = "ipmi0";
      # Leave the IPMI interface alone — static config lives on the BMC.
      linkConfig.Unmanaged = true;
    };
  };

  # Prevent host from claiming the Zigbee stick — passed through to the HA VM.
  boot.blacklistedKernelModules = ["cp210x"];
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0660", GROUP="kvm"
  '';

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18.extend (
      self: super: {
        kernel = super.kernel.override {
          structuredExtraConfig = with lib.kernel; {
            # WARNING: X86_NATIVE_CPU detects the build machine's CPU at compile time.
            # This host must be built on sparkle itself (or a machine with an identical CPU).
            # Building on a different microarchitecture will produce a mismatched kernel.
            X86_NATIVE_CPU = yes;
          };
        };
      }
    );
    kernelParams = ["intel_pstate=active"];
    zfs.package = pkgs.zfs_2_4;
  };

  # With intel_pstate active, powersave lets HWP firmware handle frequency scaling.
  powerManagement.cpuFreqGovernor = "powersave";

  system.stateVersion = "26.05";
}
