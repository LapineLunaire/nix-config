{
  sops = {
    secrets."forgejo-db-password" = {
      sopsFile = ./database.yaml;
      restartUnits = ["forgejo.service"];
    };
    secrets."forgejo-smtp-password" = {
      sopsFile = ../../smtp.yaml;
      key = "smtp-password";
      restartUnits = ["forgejo.service"];
    };
  };
}
