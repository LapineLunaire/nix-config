{
  hardware.graphics.enable = true;

  services.kmscon = {
    enable = true;
    config = {
      hwaccel = true;
      font-name = "JetBrainsMono Nerd Font";
      xkb-layout = "us";
      xkb-variant = "colemak";
    };
  };
}
