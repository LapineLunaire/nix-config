{
  config,
  net,
  web,
  lib,
  pkgs,
  ...
}: {
  imports = [./sops.nix ./vpn.nix];

  microvm = {
    vcpu = 2;
    mem = 1024;
    initialBalloonMem = 256;
  };

  # Keep qBittorrent's recorded save paths. NFS uses the guest network; torrents use qbtvpn.
  fileSystems."/mnt/samba/torrents" = {
    device = "${net.vmAddress.vault}:/vault/torrents";
    fsType = "nfs4";
    options = [
      "nosuid"
      "nodev"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.mount-timeout=20"
      "x-systemd.idle-timeout=600"
      "noatime"
    ];
  };

  # The endpoint address is held in SOPS; verify its port when replacing the VPN configuration.
  microvmGuest.egress = [
    {
      proto = "udp";
      ports = [51820];
    }
  ];

  services.qbittorrent = {
    enable = true;
    openFirewall = false;
    webuiPort = web.endpoints.qbittorrent.port;
    serverConfig = {
      Core.AutoDeleteAddedTorrentFile = "Never";
      Preferences.WebUI = {
        LocalHostAuth = true;
        Password_PBKDF2 = "@WEBUI_PASSWORD_PBKDF2@";
      };
      BitTorrent.Session = {
        DefaultSavePath = "/mnt/samba/torrents";
        TempPath = "/mnt/samba/torrents/incomplete";
        TempPathEnabled = true;
        AnonymousModeEnabled = true;
        GlobalMaxSeedingMinutes = -1;
        MaxActiveTorrents = -1;
        MaxActiveDownloads = 8;
        MaxActiveUploads = -1;
      };
    };
  };

  # Run as qBittorrent after its generated ExecStartPre installs the configuration.
  systemd.services.qbittorrent.serviceConfig.ExecStartPre = lib.mkAfter [
    "${pkgs.replace-secret}/bin/replace-secret '@WEBUI_PASSWORD_PBKDF2@' ${config.sops.secrets."qbittorrent-admin-password-hash".path} /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
  ];
}
