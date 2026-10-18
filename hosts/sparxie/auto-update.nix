{
  imports = [../../modules/nixos/nix/auto-update.nix];

  host.autoUpdate = {
    owner = "carmilla";
    branch = "main";
  };
}
