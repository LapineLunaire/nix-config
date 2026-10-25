{
  boot.plymouth.enable = true;

  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "rd.udev.log_level=3"
  ];
  boot.loader.timeout = 0;
}
