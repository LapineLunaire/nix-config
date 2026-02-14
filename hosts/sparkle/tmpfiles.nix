{...}: {
  systemd.tmpfiles.rules = [
    # ACME certificates
    "z '/var/lib/acme' 0750 acme acme - -"

    # Forgejo state directories
    "z '/var/lib/forgejo' 0750 forgejo forgejo - -"
    "z '/var/lib/forgejo/custom' 0750 forgejo forgejo - -"

    # PostgreSQL data directory
    "z '/var/lib/postgresql' 0750 postgres postgres - -"

    # qBittorrent download directories
    "z '/mnt/samba/torrents' 0755 qbittorrent qbittorrent - -"
    "z '/mnt/samba/torrents/incomplete' 0755 qbittorrent qbittorrent - -"

    # Home Assistant config
    "z '/persist/var/lib/hass' 0700 root root - -"

    # Secure Boot keys directory
    "z '/var/lib/sbctl' 0700 root root - -"
  ];
}
