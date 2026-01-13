{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.userConfig.programs;
in {
  options.userConfig.programs = {
    gui.enable = lib.mkEnableOption "GUI applications";
    gaming.enable = lib.mkEnableOption "gaming applications";
    nixd.enable = lib.mkEnableOption "nixd LSP";
  };

  config = lib.mkMerge [
    {
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
    }

    (lib.mkIf cfg.gui.enable {
      programs.ghostty = {
        enable = true;
        settings = {
          window-decoration = false;
          gtk-titlebar = false;
          window-padding-x = 8;
          window-padding-y = 8;
        };
      };

      programs.rofi = {
        enable = true;
        extraConfig = {
          modi = "drun,run";
          show-icons = true;
          drun-display-format = "{name}";
        };
      };

      programs.zed-editor = {
        enable = true;

        userSettings = {
          telemetry.metrics = false;
          load_direnv = "shell_hook";
          vim_mode = true;
          hour_format = "hour24";
          lsp.nixd.settings.nixpkgs.expr = "import <nixpkgs> {}";
        };
        extensions = [
          "nix"
        ];
      };

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-pipewire-audio-capture
          obs-vaapi
          wlrobs
        ];
      };

      gtk.iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    })

    (lib.mkIf cfg.nixd.enable {
      home.packages = [
        inputs.nixd.packages.${pkgs.stdenv.hostPlatform.system}.nixd
      ];
    })
  ];
}
