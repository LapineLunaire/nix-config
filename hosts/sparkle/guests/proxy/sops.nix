{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."lunaire-moe-dns-api-token" = {};
    secrets."wireguard-private-key" = {};
  };
}
