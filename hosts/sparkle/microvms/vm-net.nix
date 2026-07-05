# Addresses on the vm-br0 bridge, derived from vm-registry.nix. Import this instead of hardcoding 10.28.34.x literals.
let
  registry = import ./vm-registry.nix;
in {
  # Host bridge address: default gateway, DNS resolver, and the source address of proxied Caddy traffic for all VMs.
  hostAddress = "10.28.34.1";
  # Per-VM addresses: name to 10.28.34.<index>.
  vmAddress = builtins.mapAttrs (_: vm: "10.28.34.${toString vm.index}") registry;
  # VMs allowed to reach postgres on 5432: DB-backed apps, uptime-kuma (health check), and pgadmin (admin).
  postgresClients = ["authelia" "forgejo" "vaultwarden" "uptime-kuma" "pgadmin"];
}
