{
  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets."ejabberd-db-password".restartUnits = ["postgresql-passwords.service"];
    secrets."carmilla-db-password".restartUnits = ["postgresql-passwords.service"];
    secrets."redis-password" = {
      owner = "redis";
      restartUnits = ["redis.service"];
    };
    secrets."tuwunel-registration-token" = {};
    secrets."pub-bnnuy-password-hash" = {};
  };
}
