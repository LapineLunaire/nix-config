{...}: {
  services.kanshi = {
    enable = true;
    systemdTarget = "sway-session.target";
  };
}
