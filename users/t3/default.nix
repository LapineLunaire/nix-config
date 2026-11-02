# The t3 user runs the T3 Code server, so agents cannot read Carmilla's home, use doas, or reach her YubiKey.
{
  config,
  lib,
  pkgs,
  ...
}: let
  nixosConfig = config;
in {
  users.groups.t3 = {};
  users.users.t3 = {
    # A system account gets a UID below 1000, so the login screen and Plasma's user list leave it out.
    isSystemUser = true;
    description = "T3 Code agents";
    group = "t3";
    # For `machinectl shell t3@`; system accounts default to nologin.
    useDefaultShell = true;
    # /var/lib is persisted on the desktops.
    home = "/var/lib/t3";
    createHome = true;
    homeMode = "700";
    # Starts the server at boot and keeps it running without a login.
    linger = true;
  };

  nix.settings.allowed-users = ["t3"];
  host.trustedTCPPorts = [3773];

  # Agents can read anything world-readable. Keep the configuration checkout private to Carmilla.
  systemd.tmpfiles.rules = ["z ${config.host.flakePath} 0700 - - -"];

  home-manager.users.t3 = {config, ...}: {
    imports = [../carmilla/coding-agents.nix];

    programs.claude-code.context = ./agents.md;
    programs.codex.context = ./agents.md;

    home = {
      username = "t3";
      homeDirectory = "/var/lib/t3";
      inherit (nixosConfig.home-manager.users.carmilla.home) stateVersion;
      packages = [pkgs.forgejo-cli];
    };
    xdg.enable = true;
    systemd.user.startServices = "sd-switch";

    # Agents commit as T3 Code and never sign. Carmilla signs when she lands their work.
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "T3 Code";
          email = "t3@lunaire.moe";
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        commit.gpgsign = false;
        tag.gpgsign = false;
      };
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };

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
  };
}
