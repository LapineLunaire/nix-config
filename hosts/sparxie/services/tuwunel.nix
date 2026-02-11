{...}: {
  services.matrix-tuwunel = {
    enable = true;
    settings.global = {
      server_name = "bunny.enterprises";
      port = [6167];
      address = ["::1"];
      allow_registration = true;
      allow_federation = true;
      allow_encryption = true;
    };
  };
}
