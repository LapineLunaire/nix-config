{
  config,
  inputs,
  lib,
  ...
}: let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  imports = [
    ./packages.nix
    ./security.nix
    ./services.nix
    ../secureboot
  ];

  networking.wireless.enable = lib.mkForce false;

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = lib.mkDefault (!config.secureboot.enable);
      efi.canTouchEfiVariables = true;
    };
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      flake-registry = "";
      auto-optimise-store = true;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  boot.kernel.sysctl."vm.swappiness" = 100;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
    priority = 100;
  };

  time.timeZone = "Europe/Amsterdam";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "C.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    earlySetup = true;
  };
}
