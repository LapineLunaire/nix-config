{config, ...}: {
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
      ls = "ls --color=auto";
      ll = "ls -lh --color=auto";
      la = "ls -lah --color=auto";
      # CoW copy on btrfs/zfs
      cp = "cp --reflink=auto --sparse=always";
    };
  };
}
