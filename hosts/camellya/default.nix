{pkgs, ...}: {
  imports = [
    ../generic
    ./hardware-configuration.nix
    ./persistence.nix
  ];

  hostConfig.desktop.enable = true;
  hostConfig.gaming.enable = true;

  home-manager.users.lapine = {
    userConfig.desktop.enable = true;
    userConfig.gui.enable = true;
    userConfig.gaming.enable = true;
    userConfig.nixd.enable = true;
  };

  networking = {
    hostName = "camellya";
    # TODO: Generate with: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
    hostId = "00000000";
    networkmanager.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = ["amd_pstate=active"];
  };

  system.stateVersion = "25.11";
}
