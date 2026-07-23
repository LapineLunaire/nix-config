# Factory for an interactive fleet user: the OS account, the shared home-manager settings, and the generic home base (the userConfig option surface and platform-derived plumbing), parameterized by identity so a new user is `import ../common.nix { name = ...; uid = ...; sshKeys = ...; homeImports = [...]; }`. The login password comes from the sops secret `<name>-password-hash`, declared per host.
{
  name,
  uid,
  sshKeys,
  description ? name,
  # Home-manager modules layered on the generic base: this user's own packages, programs, and desktop config.
  homeImports ? [],
}: {
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager.backupFileExtension = "bak";

  users.users.${name} =
    {
      inherit name;
      home =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/Users/${name}"
        else "/home/${name}";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = sshKeys;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      isNormalUser = true;
      inherit uid description;
      hashedPasswordFile = config.sops.secrets."${name}-password-hash".path;
      extraGroups =
        ["wheel"]
        ++ lib.optionals config.networking.networkmanager.enable ["networkmanager"]
        ++ lib.optionals config.home-manager.users.${name}.userConfig.desktop.enable ["video" "audio" "input"];
    };

  home-manager.users.${name} = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: {
    imports = homeImports;

    options.userConfig = {
      desktop.enable = lib.mkEnableOption "desktop environment configuration";
      # GUI machines: Linux desktops plus all darwin hosts. Derived from desktop.enable and the platform, do not set directly.
      gui = lib.mkOption {
        type = lib.types.bool;
        readOnly = true;
        default = config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin;
      };
    };

    config = {
      home = {
        username = name;
        homeDirectory = osConfig.users.users.${name}.home;
        stateVersion =
          if config.userConfig.gui
          then "26.11"
          else "26.05";
      };

      programs.home-manager.enable = true;

      # Activate new and changed systemd user services on `home-manager switch` without requiring a logout/login cycle.
      systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
    };
  };
}
