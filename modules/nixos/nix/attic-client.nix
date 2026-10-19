{
  cache,
  publicKey,
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
    extra-substituters = ["https://cache.lunaire.moe/${cache}?priority=10"];
    extra-trusted-public-keys = [publicKey];
    netrc-file = config.sops.templates."nix-netrc".path;
  };
}
