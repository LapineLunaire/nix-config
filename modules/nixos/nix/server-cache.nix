import ./attic-client.nix {
  cache = (import ./caches.nix).server;
  sopsFile = ../../../profiles/server/secrets.yaml;
}
