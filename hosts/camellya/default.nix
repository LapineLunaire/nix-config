{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nixos/generic
    ../../modules/nixos/desktop
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./pipewire.nix
    ./samba-mounts.nix
  ];

  secureboot.enable = true;

  networking = {
    hostName = "camellya";
  };

  # sshd only accepts connections from the trusted client subnets.
  services.openssh.openFirewall = false;
  networking.firewall.extraInputRules = ''
    ip saddr { ${(import ../../modules/nixos/trusted-subnets.nix).nftSet} } tcp dport 22 accept
  '';

  boot = {
    kernelPackages = pkgs.linuxPackages_7_1.extend (
      self: super: {
        kernel = super.kernel.override {
          structuredExtraConfig = with lib.kernel; {
            # WARNING: X86_NATIVE_CPU detects the build machine's CPU at compile time.
            # This host must be built on camellya itself (or a machine with an identical CPU).
            # Building on a different microarchitecture will produce a mismatched kernel.
            X86_NATIVE_CPU = yes;
          };
        };
      }
    );
    # With amd_pstate active, powersave lets the firmware (CPPC) handle frequency scaling.
    kernelParams = ["amd_pstate=active"];
  };

  powerManagement.cpuFreqGovernor = "powersave";

  # SMART monitoring without mail notifications: camellya has no mail relay, so alerts land in the journal only.
  services.smartd.enable = true;

  services.udev.packages = with pkgs; [
    wooting-udev-rules
  ];

  services.xserver.videoDrivers = ["nvidia"];

  system.stateVersion = "26.11";
}
