{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.nh];
  environment.variables.NH_FLAKE = config.host.flakePath;

  launchd.daemons.nh-clean = {
    command = "${lib.getExe pkgs.nh} clean all --keep 3";
    path = ["${config.nix.package}/bin"];
    serviceConfig = {
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Hour = 0;
          Minute = 0;
        }
      ];
    };
  };
}
