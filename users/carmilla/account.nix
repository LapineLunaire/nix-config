{
  lib,
  pkgs,
  ...
}: {
  # Minimal shared account: identity only, no shell or password assumptions, so it is safe on full hosts and stripped-down microvm guests alike. The full user (default.nix) and the guest baseline (guest.nix) both build on this.
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
