{
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;

  # Also disables hibernation.
  security.protectKernelImage = true;

  boot.kernelParams = [
    # Keep kernel memory caches separate to make memory attacks harder.
    "slab_nomerge"
    # Randomise the order of free memory pages.
    "page_alloc.shuffle=1"
  ];

  boot.kernel.sysctl = {
    # Hide restricted kernel addresses, even from root.
    "kernel.kptr_restrict" = 2;
    # Require elevated privileges for dmesg.
    "kernel.dmesg_restrict" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    # Reject packets arriving on the wrong interface for their source.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Disable ICMP redirects by default.
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  security.apparmor.enable = true;
  security.apparmor.enableCache = true;
  security.apparmor.killUnconfinedConfinables = true;

  security.sudo.enable = false;

  nix.settings.allowed-users = ["@users"];
}
