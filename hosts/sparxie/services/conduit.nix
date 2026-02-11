{...}: {
  services.matrix-conduit = {
    enable = true;
    settings.global = {
      server_name = "bunny.enterprises";
      port = 6167;
      address = "::1";
      database_backend = "rocksdb";
      allow_registration = true;
      allow_federation = true;
      allow_encryption = true;
    };
  };
}
