{...}: {
  systemd.tmpfiles.rules = [
    # Secure Boot keys directory
    "d '/var/lib/sbctl' 0700 root root - -"
  ];
}
