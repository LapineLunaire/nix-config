{
  imports = [
    ./account.nix
    ./home.nix
  ];

  users.users.carmilla.extraGroups = ["wheel"];
}
