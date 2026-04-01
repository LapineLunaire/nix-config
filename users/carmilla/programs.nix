{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    programs.tealdeer = {
      enable = true;
      settings = {
        updates = {
          auto_update = true;
        };
      };
    };

    programs.htop = {
      enable = true;
      settings = {
        show_program_path = 0;
        show_merged_command = 1;
        highlight_base_name = 1;
        tree_view = 1;
        hide_userland_threads = 1;
      };
    };

    programs.tmux = {
      enable = true;
      mouse = true;
      keyMode = "vi";
      baseIndex = 1;
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
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          cp = "cp --reflink=auto --sparse=always";
          sops = "SOPS_AGE_KEY_FILE=<(sudo cat /etc/ssh/ssh_host_ed25519_key | ssh-to-age -private-key) sops";
        }
        // lib.optionalAttrs (config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin) {
          cat = "bat";
          ls = "eza";
          ll = "eza -l";
          la = "eza -la";
        };
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  }

  (lib.mkIf (config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin) {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      package = pkgs.openssh.override {withFIDO = true;};
      matchBlocks."*" = {
        identityFile = [
          "~/.ssh/id_ed25519_sk_rk_lapine"
          "~/.ssh/id_ed25519_sk_rk_lapine2"
        ];
        identitiesOnly = true;
      };
    };

    programs.yazi = {
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

    programs.zed-editor = {
      enable = true;
      userSettings = {
        telemetry.metrics = false;
        load_direnv = "shell_hook";
        vim_mode = true;
        hour_format = "hour24";
        languages.Nix.language_servers = ["nixd" "!nil"];
        lsp.nixd.settings = {
          nixpkgs.expr = "import <nixpkgs> {}";
          formatting.command = ["alejandra"];
        };
      };
      extensions = ["nix"];
      extraPackages = with pkgs; [nixd alejandra];
    };

    programs.fastfetch = {
      enable = true;
      settings = {
        modules = [
          "title"
          "separator"
          "os"
          "kernel"
          "uptime"
          "packages"
          "shell"
          "terminal"
          "terminalfont"
          "wm"
          "wmtheme"
          {
            type = "display";
            compactType = "original";
          }
          "cpu"
          "gpu"
          {
            type = "memory";
            format = "{} / {}";
          }
          {
            type = "disk";
            folders = "/";
          }
          {
            type = "disk";
            folders = "/nix";
          }
          "localip"
          "break"
          "colors"
        ];
      };
    };
  })

  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    programs.nh = {
      enable = true;
      flake = "/users/carmilla/projects/nix-config";
    };
  })

  (lib.mkIf config.userConfig.desktop.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        window-decoration = false;
        gtk-titlebar = false;
        window-padding-x = 8;
        window-padding-y = 8;
        background-opacity = 0.95;
      };
    };

    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vaapi
      ];
    };
  })
]
