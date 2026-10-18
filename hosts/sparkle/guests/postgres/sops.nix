{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."attic-db-password" = {
      sopsFile = ../attic/database.yaml;
      restartUnits = ["postgresql-passwords.service"];
    };
    secrets."authelia-db-password" = {
      sopsFile = ../authelia/database.yaml;
      restartUnits = ["postgresql-passwords.service"];
    };
    secrets."forgejo-db-password" = {
      sopsFile = ../forgejo/database.yaml;
      restartUnits = ["postgresql-passwords.service"];
    };
    secrets."vaultwarden-db-password" = {
      sopsFile = ../vaultwarden/database.yaml;
      restartUnits = ["postgresql-passwords.service"];
    };
    secrets."carmilla-db-password".restartUnits = ["postgresql-passwords.service"];
  };
}
