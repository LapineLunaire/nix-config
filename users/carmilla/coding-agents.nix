# Shared by Carmilla and the t3 agent user.
{pkgs, ...}: let
  # programs.codex names the plugin after the derivation.
  superpowers = pkgs.fetchFromGitHub {
    name = "superpowers";
    owner = "obra";
    repo = "superpowers";
    rev = "v7.0.0";
    hash = "sha256-UCVI+T7j1Xh1LDkrvnJduis7eHFqrizCyGTWAGW5d6U=";
  };
in {
  programs.claude-code = {
    enable = true;
    settings.includeCoAuthoredBy = false;
    plugins.superpowers = superpowers;
  };

  programs.codex = {
    enable = true;
    mutableSettings = true;
    plugins = [superpowers];
  };
}
