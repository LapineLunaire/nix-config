{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."lunaire-moe-dns-api-token".sopsFile = ../../lunaire-moe-dns.yaml;
    secrets."wireguard-private-key" = {};
  };
}
