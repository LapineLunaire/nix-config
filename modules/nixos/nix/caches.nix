# The Attic caches on cache.lunaire.moe.
let
  cache = name: publicKey: {
    url = "https://cache.lunaire.moe/${name}?priority=10";
    inherit publicKey;
  };
in {
  desktop = cache "desktop" "desktop:QBHQfUrDyPKWwQolz4KiaJ1NlC+dGZLP4m29qgvkYs4=";
  server = cache "server" "server:oFkIrocLJr2oRVgeOqJ1TUUPwTYLWKm0Lpg9aRKU5zU=";
}
