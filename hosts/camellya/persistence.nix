# Host directories on top of the impermanence baseline in modules/nixos/generic/persistence.nix.
{...}: {
  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
    "/var/lib/NetworkManager"
    "/var/lib/sbctl"
    "/var/lib/waydroid"
  ];
}
