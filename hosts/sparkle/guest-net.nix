let
  registry = import ./guest-registry.nix;
  dmz = import ./dmz-net.nix;
  trustedSubnets = import ../trusted-subnets.nix;
  # Include the router that repeats LAN discovery.
  discoverySources = [trustedSubnets.lan dmz.gateway];
  names = builtins.attrNames registry;
  vmAddress = builtins.mapAttrs (_: vm: "${dmz.guestPrefix}.${toString vm.index}") registry;
  # Guests whose registry entry sets this flag.
  flagged = flag: builtins.filter (name: registry.${name}.${flag} or false) names;
  postgresDatabases = flagged "database";
  addressesNft = guests: builtins.concatStringsSep ", " (map (name: vmAddress.${name}) guests);
in {
  inherit vmAddress postgresDatabases discoverySources;
  discoverySourcesNft = builtins.concatStringsSep ", " discoverySources;
  tapsNft = builtins.concatStringsSep ", " (map (name: "\"${name}\"") names);
  # Pin each tap to its assigned IPv4 address.
  guestIdentityNft = builtins.concatStringsSep ", " (map (name: "\"${name}\" . ${vmAddress.${name}}") names);
  # pgadmin, and uptime-kuma for its port check.
  postgresClientsNft = addressesNft (postgresDatabases ++ ["pgadmin" "uptime-kuma"]);
  postgresPort = 5432;
  # Exports specify paths and modes; this list controls network access.
  nfsClientsNft = addressesNft (flagged "nfs");
  nfsPort = 2049;
  nodeExporterPort = 9100;
}
