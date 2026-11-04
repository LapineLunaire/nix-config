{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.t3code = {
    enable = true;
    mutableClientSettings = true;
  };

  # Keep local agents off: they would run as Carmilla.
  home.activation.t3codeDesktopClientOnly = lib.hm.dag.entryAfter ["linkGeneration"] (
    lib.hm.generators.mkImpureConfigMerger {
      inherit pkgs;
      format = "json";
      empty = "{}";
      jqOperation = "$dynamic * $static";
      path = "${config.home.homeDirectory}/.t3/userdata/desktop-settings.json";
      staticSettings = (pkgs.formats.json {}).generate "t3code-desktop-settings" {
        localEnvironmentEnabled = false;
      };
    }
  );
}
