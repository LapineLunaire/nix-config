{...}: {
  # Secure Boot keys directory
  systemd.tmpfiles.rules = ["d '/var/lib/sbctl' 0700 root root - -"];
}
