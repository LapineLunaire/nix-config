{config, ...}: {
  sops.secrets."attic-pull-token" = {};
  sops.templates."nix-netrc" = {
    mode = "0400";
    content = ''
      machine cache.lunaire.moe password ${config.sops.placeholder."attic-pull-token"}
    '';
  };

  nix.settings = {
    extra-substituters = ["https://cache.lunaire.moe/desktop?priority=10"];
    extra-trusted-public-keys = ["desktop:QBHQfUrDyPKWwQolz4KiaJ1NlC+dGZLP4m29qgvkYs4="];
    netrc-file = config.sops.templates."nix-netrc".path;
  };
}
