{...}: {
  systemd.tmpfiles.rules = [
    # ACME certificates
    "d '/var/lib/acme' 0750 acme acme - -"
    "z '/var/lib/acme' 0750 acme acme - -"

    # Misc samba share
    "d '/mnt/samba/misc' 0755 carmilla users - -"
    "z '/mnt/samba/misc' 0755 carmilla users - -"

    # Secure Boot keys directory
    "d '/var/lib/sbctl' 0700 root root - -"
    "z '/var/lib/sbctl' 0700 root root - -"
  ];
}
