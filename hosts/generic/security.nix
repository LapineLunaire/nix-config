{
  config,
  lib,
  ...
}: {
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (
          subject.isInGroup("wheel") &&
          [
            "org.freedesktop.login1.reboot",
            "org.freedesktop.login1.reboot-multiple-sessions",
            "org.freedesktop.login1.power-off",
            "org.freedesktop.login1.power-off-multiple-sessions",
          ].indexOf(action.id) !== -1
        ) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  security.rtkit = lib.mkIf config.hostConfig.desktop.enable {
    enable = true;
  };
}
