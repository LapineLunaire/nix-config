{...}: {
  home-manager.users.carmilla.programs.plasma = {
    enable = true;

    workspace.lookAndFeel = "org.kde.breezedark.desktop";

    input.keyboard.layouts = [
      {
        layout = "us";
        variant = "colemak";
      }
      {
        layout = "us";
      }
    ];
  };
}
