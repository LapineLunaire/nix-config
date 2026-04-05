{...}: {
  systemd.tmpfiles.rules = [
    # Authelia state directory
    "d '/var/lib/authelia-main' 0700 authelia-main authelia-main - -"
    "z '/var/lib/authelia-main' 0700 authelia-main authelia-main - -"

    # ACME certificates
    "d '/var/lib/acme' 0750 acme acme - -"
    "z '/var/lib/acme' 0750 acme acme - -"

    # Forgejo state directories
    "d '/var/lib/forgejo' 0750 forgejo forgejo - -"
    "z '/var/lib/forgejo' 0750 forgejo forgejo - -"
    "d '/var/lib/forgejo/custom' 0750 forgejo forgejo - -"
    "z '/var/lib/forgejo/custom' 0750 forgejo forgejo - -"

    # PostgreSQL data directory
    "d '/var/lib/postgresql' 0750 postgres postgres - -"
    "z '/var/lib/postgresql' 0750 postgres postgres - -"

    # Misc samba share
    "d '/mnt/samba/misc' 0755 carmilla users - -"
    "z '/mnt/samba/misc' 0755 carmilla users - -"

    # qBittorrent download directories
    "d '/mnt/samba/torrents' 0755 qbittorrent qbittorrent - -"
    "z '/mnt/samba/torrents' 0755 qbittorrent qbittorrent - -"
    "d '/mnt/samba/torrents/incomplete' 0755 qbittorrent qbittorrent - -"
    "z '/mnt/samba/torrents/incomplete' 0755 qbittorrent qbittorrent - -"

    # Home Assistant config
    "d '/persist/var/lib/hass' 0700 root root - -"
    "z '/persist/var/lib/hass' 0700 root root - -"

    # Vaultwarden data
    "d '/persist/var/lib/vaultwarden' 0700 root root - -"
    "z '/persist/var/lib/vaultwarden' 0700 root root - -"

    # pgAdmin data (container runs as UID 5050)
    "d '/persist/var/lib/pgadmin' 0700 5050 5050 - -"
    "z '/persist/var/lib/pgadmin' 0700 5050 5050 - -"

    # DynamicUser services get a private /var/lib/private/<name> bind-mounted into the unit's namespace.
    # Impermanence can't bind-mount individual subdirs of this, so the entire /var/lib/private directory is persisted instead.
    "d '/persist/var/lib/private' 0700 root root - -"
    "z '/persist/var/lib/private' 0700 root root - -"
    "d '/var/lib/private' 0700 root root - -"
    "z '/var/lib/private' 0700 root root - -"

    # Secure Boot keys directory
    "d '/var/lib/sbctl' 0700 root root - -"
    "z '/var/lib/sbctl' 0700 root root - -"
  ];
}
