{pkgs, ...}: {
  imports = [../desktop.nix];

  home-manager.users.carmilla = {
    programs.plasma = {
      workspace.wallpaper = "${../wallpapers/__camellya_wuthering_waves_drawn_by_lemontea_ekvr5838__1ba4f9536e85b04a5d04733db7eee4e9.png}";
      kscreenlocker.appearance.wallpaper = "${../wallpapers/__camellya_wuthering_waves_drawn_by_bantish__231537f8c01272b8cb8f88e7a518a7a8.jpg}";
    };

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
