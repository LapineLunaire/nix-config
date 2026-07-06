# Kernel, network, and user-account hardening shared by full hosts (via modules/nixos/generic) and the sparkle microvm guests (hosts/sparkle/microvms/guest.nix). Host-only pieces (polkit, doas) live with their consumers.
{...}: {
  # "!" locks the root account; no password login is possible.
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;

  security.protectKernelImage = true;
  # KPTI: mitigates Meltdown-class attacks by isolating kernel page tables from user space.
  security.forcePageTableIsolation = true;

  boot.kernelParams = [
    # Prevents slab cache merging, hardens against heap exploits.
    "slab_nomerge"
    # Randomises page allocator freelist order.
    "page_alloc.shuffle=1"
  ];

  boot.kernel.sysctl = {
    # Hide kptrs even for processes with CAP_SYSLOG.
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg to root.
    "kernel.dmesg_restrict" = 1;
    # Mitigate SYN flood attacks.
    "net.ipv4.tcp_syncookies" = 1;
    # Enable strict reverse path filtering (that is, do not attempt to route packets that "obviously" do not belong to the iface's network; dropped packets are logged as martians).
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    # Ignore broadcast ICMP (mitigate SMURF).
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Ignore incoming ICMP redirects (note: default is needed to ensure that the setting is applied to interfaces added after the sysctls are set).
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Ignore outgoing ICMP redirects (this is ipv4 only).
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  security.apparmor.enable = true;
  security.apparmor.enableCache = true;
  security.apparmor.killUnconfinedConfinables = true;

  security.sudo.enable = false;

  # Restrict nix-daemon access to the users group.
  nix.settings.allowed-users = ["@users"];
}
