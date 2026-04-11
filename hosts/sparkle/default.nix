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
  ];

  secureboot.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  networking = {
    hostName = "sparkle";
    hostId = "d38a0d1c";
  };

  # Interface names (sfp0, sfp1, ipmi0) are assigned by sops-rendered .link files
  # in /etc/systemd/network/ based on MAC addresses. DHCP on both SFP+ uplinks;
  # ipmi0 is left unmanaged — its static IP is configured on the BMC itself.
  systemd.network.networks = {
    "10-sfp0" = {
      matchConfig.Name = "sfp0";
      networkConfig.DHCP = "yes";
      # Use CoreDNS on the host itself; don't accept DNS from DHCP.
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
    };
    "10-sfp1" = {
      matchConfig.Name = "sfp1";
      networkConfig.DHCP = "yes";
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
    };
    "99-ipmi0" = {
      matchConfig.Name = "ipmi0";
      # Leave the IPMI interface alone — static config lives on the BMC.
      linkConfig.Unmanaged = true;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_19.extend (self: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          # WARNING: X86_NATIVE_CPU detects the build machine's CPU at compile time.
          # This host must be built on sparkle itself (or a machine with an identical CPU).
          # Building on a different microarchitecture will produce a mismatched kernel.
          X86_NATIVE_CPU = yes;
        };
      };
    });
    kernelParams = ["intel_pstate=active"];
    zfs.package = pkgs.zfs_2_4;
  };

  # With intel_pstate active, powersave lets HWP firmware handle frequency scaling.
  powerManagement.cpuFreqGovernor = "powersave";

  system.stateVersion = "26.05";
}
