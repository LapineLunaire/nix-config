{
  imports = [../desktop.nix];

  home-manager.users.carmilla.programs.plasma = {
    workspace.wallpaper = "${../wallpapers/__trailblazer_stelle_and_kafka_honkai_and_1_more_drawn_by_rafaelaaa__70a37251632a5d567b2ea3e907c27cfb.jpg}";
    kscreenlocker.appearance.wallpaper = "${../wallpapers/__kafka_silver_wolf_and_blade_honkai_and_1_more_drawn_by_eiryu33__33516ee718464cde3c995ff00a7f9275.png}";
  };
}
