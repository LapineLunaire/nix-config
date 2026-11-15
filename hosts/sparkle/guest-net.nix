let
  registry = import ./guest-registry.nix;
  dmz = import ./dmz-net.nix;
  names = builtins.attrNames registry;
  vmAddress = builtins.mapAttrs (_: vm: "${dmz.guestPrefix}.${toString vm.index}") registry;
  # Each gets a PostgreSQL database and role of its own name, with the password
  # <name>-db-password from hosts/sparkle/guests/<name>/database.yaml.
  postgresDatabases = ["attic" "authelia" "forgejo" "vaultwarden"];
in {
  inherit vmAddress postgresDatabases;
  tapsNft = builtins.concatStringsSep ", " (map (name: "\"${name}\"") names);
  # Pin each tap to its assigned IPv4 address.
  guestIdentityNft = builtins.concatStringsSep ", " (map (name: "\"${name}\" . ${vmAddress.${name}}") names);
  postgresClientsNft = let
    # pgadmin, and uptime-kuma for its port check.
    postgresClients = postgresDatabases ++ ["pgadmin" "uptime-kuma"];
  in
    builtins.concatStringsSep ", " (map (name: vmAddress.${name}) postgresClients);
  postgresPort = 5432;
  # Exports specify paths and modes; this list controls network access.
  nfsClientsNft = let
    nfsClients = ["proxy" "kavita" "qbittorrent"];
  in
    builtins.concatStringsSep ", " (map (name: vmAddress.${name}) nfsClients);
  nfsPort = 2049;
  nodeExporterPort = 9100;
}
