{
  config,
  pkgs,
  ...
}: {
  sops.secrets."carmilla-password-hash".neededForUsers = true;

  users.users.carmilla = {
    isNormalUser = true;
    uid = 1000;
    description = "Carmilla";
    home = "/home/carmilla";
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets."carmilla-password-hash".path;
    openssh.authorizedKeys.keys = import ./ssh-keys.nix;
  };
}
