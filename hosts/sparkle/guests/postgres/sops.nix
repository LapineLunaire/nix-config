{
  lib,
  net,
  ...
}: let
  restartUnits = ["postgresql-passwords.service"];
in {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets =
      lib.listToAttrs (map (name:
        lib.nameValuePair "${name}-db-password" {
          sopsFile = ../${name}/database.yaml;
          inherit restartUnits;
        })
      net.postgresDatabases)
      // {"carmilla-db-password" = {inherit restartUnits;};};
  };
}
