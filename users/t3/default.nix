# Isolate agents from Carmilla's home, doas, and YubiKey.
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
    # Keep the account out of the desktop user lists.
    isSystemUser = true;
    description = "T3 Code agents";
    group = "t3";
    # Allow `machinectl shell t3@`; system accounts default to nologin.
    useDefaultShell = true;
    # /var/lib is persisted on the desktops.
    home = "/var/lib/t3";
    createHome = true;
    homeMode = "700";
    openssh.authorizedKeys.keys = import ../carmilla/ssh-keys.nix;
    # Run the server without a login.
    linger = true;
  };

  # Do not trust authorized keys in the agent-writable home.
  services.openssh.extraConfig = lib.mkAfter ''
    Match User t3
      AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u
  '';

  nix.settings.allowed-users = ["t3"];
  host.trustedTCPPorts = [3773];

  # Keep the checkout private: agents can read world-readable files.
  systemd.tmpfiles.rules = ["z ${config.host.flakePath} 0700 - - -"];

  home-manager.users.t3 = {config, ...}: {
    imports = [../carmilla/coding-agents.nix];

    programs.claude-code.context = ./agents.md;
    programs.codex.context = ./agents.md;

    home = {
      username = "t3";
      homeDirectory = "/var/lib/t3";
      inherit (nixosConfig.home-manager.users.carmilla.home) stateVersion;
    };
    xdg.enable = true;
    systemd.user.startServices = "sd-switch";

    # Carmilla signs when she lands agent work.
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "T3 Code";
          email = "t3@lunaire.moe";
        };
        init.defaultBranch = "main";
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
