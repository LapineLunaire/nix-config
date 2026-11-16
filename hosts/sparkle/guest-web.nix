let
  registry = import ./guest-registry.nix;
  domain = "lunaire.moe";
  endpoints = builtins.listToAttrs (map (name: {
    inherit name;
    value = registry.${name}.web;
  }) (builtins.filter (name: registry.${name} ? web) (builtins.attrNames registry)));
in {
  inherit domain endpoints;
  origin = builtins.mapAttrs (_: e: "https://${e.sub}.${domain}") endpoints;
  vhost = builtins.mapAttrs (_: e: "${e.sub}.${domain}") endpoints;
}
