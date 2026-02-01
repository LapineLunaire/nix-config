{...}: {
  systemd.tmpfiles.rules = [
    # Forgejo state directories
    "d '/var/lib/forgejo' 0750 forgejo forgejo - -"
    "d '/var/lib/forgejo/custom' 0750 forgejo forgejo - -"

    # pgAdmin DynamicUser directories
    "d '/var/lib/private' 0700 root root - -"
    "d '/var/lib/private/pgadmin' 0750 pgadmin pgadmin - -"

    # qBittorrent download directories
    "d '/mnt/samba/torrents' 0755 qbittorrent qbittorrent - -"
    "d '/mnt/samba/torrents/incomplete' 0755 qbittorrent qbittorrent - -"

    # Secure Boot keys directory
    "d '/var/lib/sbctl' 0700 root root - -"
  ];
}
