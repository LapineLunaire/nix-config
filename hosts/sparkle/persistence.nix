{...}: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/acme"
      "/var/lib/forgejo"
      "/var/lib/hass"
      "/var/lib/containers"
      "/var/lib/nixos"
      "/var/lib/postgresql"
      "/var/lib/qBittorrent"
      "/var/lib/samba"
      "/var/lib/sbctl"
      "/var/lib/systemd"
      "/var/lib/vaultwarden"
      "/var/log"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
