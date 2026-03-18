{...}: {
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;

  security.polkit.enable = true;

  environment.etc."polkit-1/rules.d/50-wheel-power.rules".text = ''
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
}
