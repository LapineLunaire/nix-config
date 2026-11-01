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
}
