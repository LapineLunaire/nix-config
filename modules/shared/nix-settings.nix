{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Enable sandboxing on macOS.
      sandbox = true;
      flake-registry = "";
      auto-optimise-store = true;
      # Build locally if cache downloads fail.
      fallback = true;
      use-xdg-base-directories = true;
    };
    channel.enable = false;
  };

  nixpkgs.config.allowUnfree = true;
}
