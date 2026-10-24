{
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";

    users.carmilla = {
      imports = [./programs.nix];

      home = {
        username = "carmilla";
        homeDirectory = config.users.users.carmilla.home;
        preferXdgDirectories = true;
      };
      xdg.enable = true;

      programs.home-manager.enable = true;
      systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
    };
  };
}
