{pkgs, ...}: {
  imports = [../desktop.nix];

  home-manager.users.carmilla = {
    home.packages = with pkgs; [
      davinci-resolve
      heroic
      prismlauncher
      wootility
      xivlauncher
    ];

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
      "x-scheme-handler/web+wootwoot" = "wootility.desktop";
      "x-scheme-handler/wootwoot" = "wootility.desktop";
    };
  };
}
