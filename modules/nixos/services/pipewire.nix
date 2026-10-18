{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Keep ALSA devices active to avoid wake-up pops.
    wireplumber.extraConfig."99-disable-suspend"."monitor.alsa.rules" = [
      {
        matches = [
          {"node.name" = "~alsa_input.*";}
          {"node.name" = "~alsa_output.*";}
        ];
        actions.update-props."session.suspend-timeout-seconds" = 0;
      }
    ];
  };
}
