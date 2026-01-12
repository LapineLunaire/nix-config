{...}: {
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "swaylock -f";
      lock = "swaylock -f";
    };
    timeouts = [
      {
        timeout = 300;
        command = "swaymsg 'output * power off'";
        resumeCommand = "swaymsg 'output * power on'";
      }
      {
        timeout = 600;
        command = "swaylock -f";
      }
    ];
  };
}
