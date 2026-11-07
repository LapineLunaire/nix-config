{
  cache,
  sopsFile,
}: {
  config,
  lib,
  ...
}: {
  sops.secrets."attic-pull-token".sopsFile = lib.mkDefault sopsFile;
  sops.templates."nix-netrc" = {
    mode = "0400";
    content = ''
      machine cache.lunaire.moe password ${config.sops.placeholder."attic-pull-token"}
    '';
  };

  nix.settings = {
    extra-substituters = [cache.url];
    extra-trusted-public-keys = [cache.publicKey];
    netrc-file = config.sops.templates."nix-netrc".path;
  };
}
