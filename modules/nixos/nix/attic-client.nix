# The one Attic cache, on the host name the proxy serves Attic on. The CI workflows in .forgejo also name it.
{
  config,
  web,
  ...
}: {
  # Every host that pulls from the cache is a recipient of this file.
  sops.secrets."attic-pull-token".sopsFile = ./attic-client.yaml;
  sops.templates."nix-netrc" = {
    mode = "0400";
    content = ''
      machine ${web.vhost.attic} password ${config.sops.placeholder."attic-pull-token"}
    '';
  };

  nix.settings = {
    extra-substituters = ["${web.origin.attic}/lune?priority=10"];
    extra-trusted-public-keys = [
      "lune:oM+bGPYSf0rIgczv1jYKHU9zubUjSFwR3IlgmRjJ3GU="
    ];
    netrc-file = config.sops.templates."nix-netrc".path;
  };
}
