{config, ...}: {
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
    };
  };
}
