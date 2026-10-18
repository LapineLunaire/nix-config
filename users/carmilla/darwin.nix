{pkgs, ...}: {
  imports = [./home.nix];

  users.users.carmilla = {
    home = "/Users/carmilla";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = import ./ssh-keys.nix;
  };

  home-manager.users.carmilla = {pkgs, ...}: {
    imports = [./applications.nix];
    home.packages = with pkgs; [iina mtr utm];
  };
}
