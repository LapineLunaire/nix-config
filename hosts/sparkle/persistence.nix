# Host directories on top of the impermanence baseline in modules/nixos/generic/persistence.nix.
{...}: {
  environment.persistence."/persist".directories = [
    "/var/lib/acme"
    "/var/lib/samba"
    "/var/lib/sbctl"
  ];
}
