{...}: {
  systemd.tmpfiles.rules = [
    # DynamicUser directories
    "d '/var/lib/private' 0700 root root - -"
    "d '/var/lib/private/tuwunel' 0700 root root - -"
  ];
}
