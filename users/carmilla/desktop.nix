{
  imports = [
    ./account.nix
    ./home.nix
  ];

  users.users.carmilla.extraGroups = ["wheel" "networkmanager"];

  home-manager.users.carmilla = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [./applications.nix ./plasma.nix];

    home.packages = with pkgs; [
      dino
      discord
      fluffychat
      high-tide
      krita
      minisign
      mission-center
      mpv
      pciutils
      proton-vpn
      protonmail-desktop
      t3code
      usbutils
    ];

    # Keep this writable for applications. A rebuild restores these associations.
    home.activation.mimeApps = let
      zed = "dev.zed.Zed.desktop";
      firefox = "firefox.desktop";

      editorTypes = [
        "text/plain"
        "text/markdown"
        "text/csv"
        "text/x-csrc"
        "text/x-chdr"
        "text/x-c++src"
        "text/x-c++hdr"
        "text/x-java"
        "text/x-makefile"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tex"
        "application/xml"
        "application/x-shellscript"
        "application/x-zerosize"
        "x-scheme-handler/zed"
      ];

      browserTypes = [
        "text/html"
        "application/xhtml+xml"
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-xht"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chrome"
      ];

      assign = types: app: lib.genAttrs types (_: app);

      defaultApplications =
        assign editorTypes zed
        // assign browserTypes firefox
        // {
          "x-scheme-handler/claude-cli" = "nix-claude-code-url-handler.desktop";
          "x-scheme-handler/proton-inbox" = "proton-mail.desktop";
        }
        // config.xdg.mimeApps.defaultApplications;

      addedAssociations = lib.mapAttrs (_: app: lib.toList app) defaultApplications;

      mimeApps = pkgs.writeText "mimeapps.list" (lib.generators.toINI
        {
          mkKeyValue = key: value: let
            entries =
              if lib.isList value
              then value
              else [value];
          in "${key}=${lib.concatStringsSep ";" entries};";
        }
        {
          "Default Applications" = defaultApplications;
          "Added Associations" = addedAssociations;
        });
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run install -Dm644 ${mimeApps} "${config.xdg.configHome}/mimeapps.list"
      '';

    xdg = {
      # App-generated handlers retain old store paths across package upgrades.
      desktopEntries = {
        nix-claude-code-url-handler = {
          name = "Claude Code URL Handler";
          exec = "${config.programs.claude-code.package}/bin/claude --handle-uri %u";
          mimeType = ["x-scheme-handler/claude-cli"];
          noDisplay = true;
        };
      };

      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME/desktop";
        documents = "$HOME/documents";
        download = "$HOME/downloads";
        music = "$HOME/music";
        pictures = "$HOME/pictures";
        projects = "$HOME/projects";
        publicShare = "$HOME/public";
        templates = "$HOME/templates";
        videos = "$HOME/videos";
      };
    };
  };
}
