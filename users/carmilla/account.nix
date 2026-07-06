{
  lib,
  pkgs,
  ...
}: {
  # Minimal shared account: identity only (name, uid, ssh keys, wheel), no shell or password. default.nix extends it for full hosts; flake.nix imports it directly into every microvm guest.
  users.users.carmilla =
    {
      name = "carmilla";
      home =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/Users/carmilla"
        else "/home/carmilla";
      openssh.authorizedKeys.keys = import ./ssh-keys.nix;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      isNormalUser = true;
      description = "Carmilla";
      uid = 1000;
      extraGroups = ["wheel"];
    };
}
