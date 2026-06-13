{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.userConfig.desktop.enable {
    services.ssh-agent.enable = true;
  };
}
