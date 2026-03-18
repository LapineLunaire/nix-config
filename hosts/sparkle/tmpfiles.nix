{...}: {
  systemd.tmpfiles.rules = [
    # ACME certificates
    "z '/var/lib/acme' 0750 acme acme - -"

    # Forgejo state directories
    "z '/var/lib/forgejo' 0750 forgejo forgejo - -"
    "z '/var/lib/forgejo/custom' 0750 forgejo forgejo - -"

    # PostgreSQL data directory
    "z '/var/lib/postgresql' 0750 postgres postgres - -"

    # Misc samba share
    "d '/mnt/samba/misc' 0755 carmilla users - -"

    # qBittorrent download directories
    "z '/mnt/samba/torrents' 0755 qbittorrent qbittorrent - -"
    "z '/mnt/samba/torrents/incomplete' 0755 qbittorrent qbittorrent - -"

    # Home Assistant config
    "z '/persist/var/lib/hass' 0700 root root - -"

    # Vaultwarden data
    "z '/persist/var/lib/vaultwarden' 0700 root root - -"

    # pgAdmin data (container runs as UID 5050)
    "d '/persist/var/lib/pgadmin' 0700 5050 5050 - -"

    # DynamicUser private directory (persisted as a whole to avoid bind mount conflicts)
    "d '/persist/var/lib/private' 0700 root root - -"
    "z '/var/lib/private' 0700 root root - -"

    # Secure Boot keys directory
    "z '/var/lib/sbctl' 0700 root root - -"
  ];
}
