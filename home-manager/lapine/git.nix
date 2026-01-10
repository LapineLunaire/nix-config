{...}: {
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

      pager.options = "--always";

      pull.rebase = true;

      init.defaultBranch = "main";

      color.ui = "auto";

      push.autoSetupRemote = true;
      rerere.enabled = true;
    };
  };
}
