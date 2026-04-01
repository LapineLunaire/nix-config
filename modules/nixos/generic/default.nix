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
      flake-registry = ""; # disable global registry, only use pinned inputs
      auto-optimise-store = true;
    };
    channel.enable = false;
    # pin registry and nixPath to flake inputs so `nix run nixpkgs#...` and `<nixpkgs>` resolve to the locked version
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # high swappiness is correct with zram — tells the kernel to prefer compressing into zram over evicting file cache
  boot.kernel.sysctl."vm.swappiness" = 100;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
    priority = 100;
  };

  time.timeZone = lib.mkDefault "UTC";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "C.UTF-8"; # ISO 8601 time format
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
