{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.t3code = {
    enable = true;
    package = pkgs.t3code.override {
      enableClaude = true;
      codex = config.programs.codex.package;
      claude-code = config.programs.claude-code.package;
    };
    mutableUserSettings = true;
    mutableKeybindings = true;
    mutableClientSettings = true;

    server = {
      enable = true;
      extraArgs = ["--host" "0.0.0.0" "--port" "3773"];
    };

    userSettings = {
      enableProviderUpdateChecks = false;
      providerInstances = {
        codex = {
          driver = "codex";
          enabled = true;
          config = {
            setupMode = "existing";
            binaryPath = lib.getExe config.programs.codex.package;
          };
        };
        claudeAgent = {
          driver = "claudeAgent";
          enabled = true;
          config.binaryPath = lib.getExe config.programs.claude-code.package;
        };
      };
    };
  };

  # The server locks ~/.t3/userdata, so the desktop app cannot run its own backend.
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
