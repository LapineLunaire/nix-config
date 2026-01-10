{...}: {
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Required for real-time audio scheduling
  security.rtkit.enable = true;
}
