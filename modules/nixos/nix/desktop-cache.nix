import ./attic-client.nix {
  cache = (import ./caches.nix).desktop;
  sopsFile = ../../../profiles/desktop/secrets.yaml;
}
