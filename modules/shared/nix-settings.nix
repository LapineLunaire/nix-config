{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Enable sandboxing on macOS.
      sandbox = true;
      # Disable the global registry.
      flake-registry = "";
      auto-optimise-store = true;
      # Build from source if downloading a cached package fails.
      fallback = true;
      use-xdg-base-directories = true;
    };
    channel.enable = false;
  };
}
