{pkgs, ...}: {
  imports = [
    ../generic
    ./hardware-configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = ["amd_pstate=active"];
  };

  networking = {
    hostName = "camellya";
    # TODO: Generate with: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
    hostId = "00000000";
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

  environment.etc."nixos".source = "/persist/nix-config";

  system.stateVersion = "25.11";
}
