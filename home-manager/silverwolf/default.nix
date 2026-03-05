{
  config,
  pkgs,
  ...
}: {
  home = {
    username = "carmilla";
    homeDirectory = "/Users/carmilla";
    stateVersion = "26.05";

    packages = with pkgs; [
      # Nix tooling
      alejandra
      nixd

      # CLI utilities
      bat
      duf
      eza
      fd
      fzf
      gping
      jq
      ldns
      mtr
      neovim
      nmap
      ripgrep
      rclone
      rsync
      tree
      whois
      yt-dlp
    ];
  };

  programs.home-manager.enable = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lapine";
        email = "lapine@lunaire.eu";
      };
      core.editor = "nvim";
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
    shellAliases = {
      pk = "pkill";
      grep = "grep --color=auto";
      egrep = "egrep --color=auto";
      fgrep = "fgrep --color=auto";
      cat = "bat";
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
    };
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
        {
          type = "memory";
          format = "{} / {}";
        }
        {
          type = "disk";
          folders = "/";
        }
        "localip"
        "break"
        "colors"
      ];
    };
  };
}
