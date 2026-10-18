{
  config,
  pkgs,
  ...
}: let
  # programs.codex names the plugin after the derivation.
  superpowers = pkgs.fetchFromGitHub {
    name = "superpowers";
    owner = "obra";
    repo = "superpowers";
    rev = "v7.0.0";
    hash = "sha256-UCVI+T7j1Xh1LDkrvnJduis7eHFqrizCyGTWAGW5d6U=";
  };
in {
  home.packages = with pkgs; [
    alejandra
    bat
    brave
    duf
    eza
    ffmpeg
    firefox
    gping
    megatools
    nixd
    nmap
    pandoc
    texliveFull
    winbox4
    yt-dlp
    yubikey-manager
  ];

  programs.claude-code = {
    enable = true;
    settings.includeCoAuthoredBy = false;
    plugins.superpowers = superpowers;
  };

  programs.codex = {
    enable = true;
    plugins = [superpowers];
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

  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isDarwin
      then pkgs.ghostty-bin
      else pkgs.ghostty;
    settings = {
      theme = "Gruvbox Dark Hard";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      background-opacity = 0.95;
      window-padding-x = 8;
      window-padding-y = 8;
      auto-update = "off";
    };
  };

  programs.git.settings = {
    user = {
      name = "Carmilla";
      email = "carmilla@lunaire.eu";
      signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_rk_carmilla";
    };
    gpg.format = "ssh";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };

  programs.nixvim = {
    plugins.lspconfig.enable = true;
    lsp.servers.nixd = {
      enable = true;
      config.settings.nixd.formatting.command = ["alejandra"];
    };

    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft.nix = ["alejandra"];
        format_on_save.lsp_format = "fallback";
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    package = pkgs.openssh;
    settings."*".IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_rk_carmilla";
  };

  programs.yazi = {
    enable = true;
    settings.mgr = {
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
      journal.hour_format = "hour24";
      theme = {
        mode = "dark";
        dark = "Gruvbox Dark Hard";
        light = "Gruvbox Light Hard";
      };
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp.nixd.settings = {
        nixpkgs.expr = "import <nixpkgs> {}";
        formatting.command = ["alejandra"];
      };
    };
    extensions = ["nix" "gruvbox"];
  };

  programs.zsh.shellAliases = {
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    tree = "eza --tree";
  };
}
