{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  config = {
    home.packages =
      lib.optionals config.userConfig.nixd.enable [
        inputs.nixd.packages.${pkgs.stdenv.hostPlatform.system}.nixd
      ]
      ++ lib.optionals config.userConfig.desktop.enable (with pkgs; [
        discord
        firefox
        heroic
        imv
        mpv
        protonmail-desktop
        protonvpn-gui
      ]);

    programs.ssh = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      matchBlocks."*" = {
        identityFile = "~/.ssh/id_ed25519_sk_rk_lapine";
        extraOptions.IdentityAgent = "none";
      };
    };

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Lapine";
          email = "lapine@lunaire.eu";
        };
        core = {
          editor = "nvim";
          pager = "nvimpager";
        };
        pull.rebase = true;
        init.defaultBranch = "main";
        color.ui = "auto";
        push.autoSetupRemote = true;
        rerere.enabled = true;
      };
    };

    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      history = {
        path = "${config.xdg.dataHome}/zsh/history";
        share = true;
      };
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initContent = ''
        setopt extendedglob nomatch
        unsetopt beep
        bindkey -v

        PROMPT='%B%F{blue}%m %F{magenta}%~ %F{blue}λ %b%f'
      '';
      shellAliases =
        {
          pk = "pkill";
          grep = "grep --color=auto";
          egrep = "egrep --color=auto";
          fgrep = "fgrep --color=auto";
          cp = "cp --reflink=auto --sparse=always";
        }
        // lib.optionalAttrs config.userConfig.desktop.enable {
          cat = "bat";
          ls = "eza";
          ll = "eza -l";
          la = "eza -la";
        };
    };

    programs.yazi = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      enableZshIntegration = true;
      settings = {
        manager = {
          show_hidden = true;
          sort_by = "natural";
          sort_dir_first = true;
        };
      };
    };

    programs.ghostty = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      settings = {
        window-decoration = false;
        gtk-titlebar = false;
        window-padding-x = 8;
        window-padding-y = 8;
      };
    };

    programs.zed-editor = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      userSettings = {
        telemetry.metrics = false;
        load_direnv = "shell_hook";
        vim_mode = true;
        hour_format = "hour24";
        lsp.nixd.settings.nixpkgs.expr = "import <nixpkgs> {}";
      };
      extensions = ["nix"];
    };

    programs.rofi = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      extraConfig = {
        modi = "drun,run";
        show-icons = true;
        drun-display-format = "{name}";
      };
    };

    programs.swaylock.enable = lib.mkIf config.userConfig.desktop.enable true;

    programs.obs-studio = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vaapi
        wlrobs
      ];
    };

    programs.waybar = lib.mkIf config.userConfig.desktop.enable {
      enable = true;
      systemd = {
        enable = true;
        target = "sway-session.target";
      };
      style = ''
        #workspaces button {
          color: @base05;
          background: transparent;
        }
        #workspaces button.focused {
          color: @base0D;
          background: @base02;
          font-weight: bold;
        }
        #workspaces button.urgent {
          color: @base08;
          background: @base01;
        }
      '';
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 8;

          modules-left = ["sway/workspaces" "sway/mode"];
          modules-center = ["clock"];
          modules-right = ["tray" "network" "cpu" "memory" "temperature"];

          tray = {
            spacing = 8;
          };

          "sway/workspaces" = {
            format = "{name}";
            disable-scroll = true;
          };

          "sway/mode" = {
            format = "{}";
          };

          clock = {
            format = "{:%Y-%m-%d %H:%M:%S}";
            interval = 1;
            tooltip-format = "<tt>{calendar}</tt>";
          };

          cpu = {
            format = "CPU {usage}%";
            interval = 2;
          };

          memory = {
            format = "RAM {percentage}%";
            interval = 2;
          };

          temperature = {
            format = "{temperatureC}°C";
            critical-threshold = 80;
          };

          network = {
            format-wifi = "{ipaddr}";
            format-ethernet = "{ipaddr}";
            format-disconnected = "Offline";
            tooltip-format = "{ifname}: {essid}";
          };
        };
      };
    };
  };
}
