# carmilla: an interactive user, present on full hosts and darwin. Identity and personal config only; the account plumbing and generic home base come from ../common.
{inputs, ...}: {
  imports = [
    (import ../common.nix {
      name = "carmilla";
      description = "Carmilla";
      uid = 1000;
      sshKeys = import ./ssh-keys.nix;
      homeImports = [
        inputs.plasma-manager.homeModules.plasma-manager
        ./desktop.nix
        ./packages.nix
        ./plasma.nix
        ./programs.nix
      ];
    })
  ];
}
