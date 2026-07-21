{
  lib,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    outputs.nixosModules.site
    outputs.nixosModules.generic
    outputs.nixosModules.packages
    outputs.nixosModules.desktop
    outputs.nixosModules.desktop-packages
    outputs.nixosModules.trusted-ssh-ingress
    ./hardware-configuration.nix
    ./persistence.nix
    ./tmpfiles.nix
    ./sops.nix
    ./pipewire.nix
    ./samba-mounts.nix
  ];

  secureboot.enable = true;

  # Desktop host: enable the user's desktop and plasma configuration.
  home-manager.users.carmilla.userConfig.desktop.enable = true;

  networking = {
    hostName = "camellya";
  };

  # Client subnets trusted to reach camellya's sshd: LAN (10.28.64.0/24), WireGuard VPN (10.28.96.0/24), Nox's LAN (10.100.0.0/24), Nox's WireGuard (10.1.0.0/24).
  site.trustedSubnets = ["10.28.64.0/24" "10.28.96.0/24" "10.100.0.0/24" "10.1.0.0/24"];

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
