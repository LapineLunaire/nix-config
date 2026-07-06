{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../nix-settings.nix
    ./packages.nix
    ./persistence.nix
    ../security.nix
    ./polkit.nix
    ./services.nix
    ../secureboot.nix
  ];

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = lib.mkDefault (!config.secureboot.enable);
      efi.canTouchEfiVariables = true;
    };
  };

  nix.settings.auto-optimise-store = true;

  # doas for full hosts: wheel escalates with a password, cached per session.
  security.doas.enable = true;
  environment.systemPackages = [pkgs.doas-sudo-shim];
  security.doas.extraRules = [
    {
      groups = ["wheel"];
      keepEnv = true;
      persist = true;
    }
  ];

  # vm.swappiness=100 is correct with zram: since zram compresses pages in RAM, swapping is cheap.
  # High swappiness lets the kernel aggressively move anonymous pages into zram rather than holding them uncompressed in RAM.
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

  networking.firewall.enable = true;
  networking.nftables.enable = true;

  # Use systemd-networkd on all servers. Desktops override this with NetworkManager via modules/nixos/desktop. Explicit useDHCP = false prevents the legacy scripted networking stack from racing with networkd.
  systemd.network.enable = lib.mkDefault true;
  networking.useDHCP = false;

  boot.zfs.forceImportRoot = false;
}
