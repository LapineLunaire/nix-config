{config, ...}: {
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
      bindkey -v # vi mode

      PROMPT='%B%F{blue}%m %F{magenta}%~ %F{blue}λ %b%f'
    '';

    shellAliases = {
      cat = "bat";
      pk = "pkill";
      grep = "grep --color=auto";
      egrep = "egrep --color=auto";
      fgrep = "fgrep --color=auto";
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      # CoW copy on btrfs/zfs
      cp = "cp --reflink=auto --sparse=always";
    };
  };
}
