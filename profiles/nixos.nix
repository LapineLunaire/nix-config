{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/shared/host.nix
    ../modules/shared/nix-settings.nix
    ../modules/nixos/system/security.nix
    ../modules/nixos/networking/firewall.nix
    ../modules/nixos/services/openssh.nix
    ../modules/nixos/programs/ghostty-terminfo.nix
    ../modules/nixos/nix/overlays.nix
  ];

  console = {
    font = "Lat2-Terminus16";
    earlySetup = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_DK.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
    };
  };

  security.doas = {
    enable = true;
    extraRules = [
      {
        groups = ["wheel"];
        persist = true;
      }
    ];
  };

  # Provide a sudo command for tools that expect it.
  environment.systemPackages = [pkgs.doas-sudo-shim];

  security.polkit.enable = true;

  # Allow wheel to reboot or shut down remotely.
  environment.etc."polkit-1/rules.d/50-wheel-power.rules".text = ''
    polkit.addRule(function (action, subject) {
      if (
        subject.isInGroup("wheel") &&
        [
          "org.freedesktop.login1.reboot",
          "org.freedesktop.login1.reboot-multiple-sessions",
          "org.freedesktop.login1.power-off",
          "org.freedesktop.login1.power-off-multiple-sessions",
        ].indexOf(action.id) !== -1
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 3";
      dates = "daily";
    };
    flake = config.host.flakePath;
  };

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  services.fwupd.enable = lib.mkDefault true;
  programs.mtr.enable = true;
  programs.zsh.enable = true;
}
