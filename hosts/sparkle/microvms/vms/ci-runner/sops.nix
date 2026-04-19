{...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."forgejo-runner-token" = {};
    templates."runner-token.env" = {};
  };
}
