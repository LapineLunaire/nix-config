{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
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
        rerere.enabled = true; # remember conflict resolutions
        diff.algorithm = "histogram"; # better diff output than default myers
        merge.conflictstyle = "zdiff3"; # shows base version in conflict markers
        branch.sort = "-committerdate";
      };
    };

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        theme_background = false;
        truecolor = true;
        vim_keys = true;
        update_ms = 1000;
      };
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      initLua = ''
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.signcolumn = 'yes'
        vim.opt.termguicolors = true
        vim.opt.undofile = true
        vim.opt.clipboard = 'unnamedplus'
      '';
    };

    programs.tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    programs.tmux = {
      enable = true;
      mouse = true;
      keyMode = "vi";
      baseIndex = 1;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
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
          # Use CoW reflinks on supported filesystems (ZFS, btrfs), falling back to a regular copy. --sparse=always avoids writing zero blocks explicitly.
          cp = "cp --reflink=auto --sparse=always";
          # Derive the sops age key on the fly from the SSH host key. Requires sudo to read /etc/ssh/ssh_host_ed25519_key.
          sops = "SOPS_AGE_KEY_FILE=<(sudo cat /etc/ssh/ssh_host_ed25519_key | ssh-to-age -private-key) sops";
        }
        // lib.optionalAttrs (config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin) {
          cat = "bat";
          ls = "eza";
          ll = "eza -l";
          la = "eza -la";
          tree = "eza --tree";
        };
    };
  }

  (lib.mkIf (config.userConfig.desktop.enable || pkgs.stdenv.hostPlatform.isDarwin) {
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

    programs.neovim.initLua = ''
      vim.lsp.config('nixd', {
        cmd = { 'nixd' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', '.git' },
        settings = {
          nixd = {
            formatting = { command = { 'alejandra' } },
          },
        },
      })
      vim.lsp.enable('nixd')

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local group = vim.api.nvim_create_augroup('lsp_format_' .. args.buf, { clear = true })
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = group,
            buffer = args.buf,
            callback = function()
              vim.lsp.buf.format({ bufnr = args.buf })
            end,
          })
        end,
      })

      require('gruvbox').setup({ contrast = 'hard' })
      vim.cmd('colorscheme gruvbox')
    '';

    programs.neovim.plugins = with pkgs.vimPlugins; [gruvbox-nvim];

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false; # deprecated by home-manager
      # Rebuild OpenSSH with FIDO2 support for sk-ssh-ed25519 resident keys stored on the YubiKey.
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
      settings.manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
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
  })

  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    programs.ghostty = {
      enable = true;
      # Ghostty is not available on nixpkgs for macOS. Use the Homebrew package instead. home-manager manages the config only.
      package = null;
      settings = {
        theme = "Gruvbox Dark Hard";
        background-opacity = 0.95;
        window-padding-x = 8;
        window-padding-y = 8;
      };
    };

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
  })
]
