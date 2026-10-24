{
  lib,
  pkgs,
  ...
}: {
  home.packages =
    (with pkgs; [
      curl
      fd
      iperf3
      jq
      ldns
      nvimpager
      rclone
      ripgrep
      rsync
      socat
      sops
      ssh-to-age
      whois
      xh
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
      # GNU commands absent from uutils remain available through the system profile.
      uutils-coreutils-noprefix
      uutils-findutils
      uutils-diffutils
      traceroute
    ]);

  home.sessionVariables = {
    PAGER = "nvimpager";
    MANPAGER = "nvimpager";
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;

  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "nvim";
        pager = "nvimpager";
      };
      pull.rebase = true;
      init.defaultBranch = "main";
      color.ui = "auto";
      push.autoSetupRemote = true;
      rerere.enabled = true;
      diff.algorithm = "histogram";
      merge.conflictstyle = "zdiff3";
      branch.sort = "-committerdate";
    };
  };

  programs.nixvim = {
    enable = true;
    nixpkgs.pkgs = pkgs;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    opts = {
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      termguicolors = true;
      undofile = true;
      clipboard = "unnamedplus";
    };

    colorschemes.gruvbox = {
      enable = true;
      settings.contrast = "hard";
    };
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

  programs.zoxide.enable = true;

  programs.zsh = {
    enable = true;
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
        # The host decryption key requires root access.
        sops = "SOPS_AGE_KEY=\"$(doas cat /etc/ssh/ssh_host_ed25519_key | ssh-to-age -private-key)\" sops";
      };
  };
}
