{...}: {
  # "!" locks the root account — no password login is possible.
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;

  security.protectKernelImage = true;

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2; # hide kernel pointers from all users
    "kernel.dmesg_restrict" = 1; # restrict dmesg to root
    "net.ipv4.tcp_syncookies" = 1; # SYN flood mitigation
    "net.ipv4.conf.all.rp_filter" = 1; # strict reverse path filtering (anti-spoofing)
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv6.conf.all.rp_filter" = 1;
    "net.ipv6.conf.default.rp_filter" = 1;
  };

  security.polkit.enable = true;

  # Allow wheel group members to reboot and power off without a password prompt.
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
