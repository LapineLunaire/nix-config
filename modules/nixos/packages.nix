# Shared system program and package choices, imported by each host alongside the generic module.
{pkgs, ...}: {
  programs.zsh.enable = true;

  # System-wide neovim so root shells have an editor; the user's configured neovim comes from home-manager.
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 3";
      dates = "daily";
    };
    flake = "/persist/nix-config";
  };

  # terminfo so SSH sessions from a Ghostty terminal render correctly.
  environment.systemPackages = [pkgs.ghostty.terminfo];
}
