# The one Attic cache. The CI workflows in .forgejo also name it.
{config, ...}: {
  # Every host that pulls from the cache is a recipient of this file.
  sops.secrets."attic-pull-token".sopsFile = ./attic-client.yaml;
  sops.templates."nix-netrc" = {
    mode = "0400";
    content = ''
      machine cache.lunaire.moe password ${config.sops.placeholder."attic-pull-token"}
    '';
  };

  nix.settings = {
    extra-substituters = ["https://cache.lunaire.moe/lune?priority=10"];
    extra-trusted-public-keys = [
      "lune:oM+bGPYSf0rIgczv1jYKHU9zubUjSFwR3IlgmRjJ3GU="
    ];
    netrc-file = config.sops.templates."nix-netrc".path;
  };
}
