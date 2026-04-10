{config, ...}: {
  sops.secrets."kavita-token-key".owner = "kavita";

  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets."kavita-token-key".path;
    settings = {
      Port = 10000;
      IpAddresses = "127.0.0.1,::1";
    };
  };
}
