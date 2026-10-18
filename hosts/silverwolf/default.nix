{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  # nix-darwin's own state version counter, unrelated to the nixpkgs release below it.
  system.stateVersion = 6;
  home-manager.users.carmilla.home.stateVersion = "26.11";

  networking = {
    hostName = "silverwolf";
    computerName = "Silver Wolf";
  };
  system.primaryUser = "carmilla";

  host.flakePath = "/Users/carmilla/projects/nix-config";
}
