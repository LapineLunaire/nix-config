{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."attic-pull-token".sopsFile = ./secrets.yaml;
    secrets."forgejo-runner-token" = {};
  };
}
