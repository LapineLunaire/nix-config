{...}: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/acme"
      "/var/lib/authelia-main"
      "/var/lib/docker"
      "/var/lib/forgejo"
      "/var/lib/vaultwarden"
      "/var/lib/nixos"
      "/var/lib/postgresql"
      "/var/lib/private"
      "/var/lib/qBittorrent"
      "/var/lib/samba"
      "/var/lib/sbctl"
      "/var/lib/systemd"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
