# The T3 Code desktop app, as a client of the server that the t3 user runs.
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

  # Its local environment would run agents as Carmilla, so a rebuild keeps it off.
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
