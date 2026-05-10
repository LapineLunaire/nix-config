{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.userConfig.desktop.enable {
    services.easyeffects.enable = true;
    services.ssh-agent.enable = true;
  };
}
