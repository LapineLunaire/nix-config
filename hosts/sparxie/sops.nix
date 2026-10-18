{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

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
