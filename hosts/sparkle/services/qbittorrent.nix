{config, ...}: {
  vpnNamespaces.qbtvpn = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."protonvpn-qbittorrent-conf".path;
    accessibleFrom = ["127.0.0.1/32"];
    portMappings = [
      {
        from = 4000;
        to = 4000;
        protocol = "tcp";
      }
    ];
    openVPNPorts = [
      {
        port = 57140;
        protocol = "both";
      }
    ];
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = false;
    webuiPort = 4000;
    torrentingPort = 57140;
    serverConfig = {
      Core.AutoDeleteAddedTorrentFile = "Never";
      Preferences.WebUI = {
        LocalHostAuth = true;
        # generate with the following command (make sure to prefix with a space to avoid going into shell history!)
        # nix run git+https://codeberg.org/feathecutie/qbittorrent_password -- -p [password here]
        Password_PBKDF2 = "@ByteArray(+WZc5S80KMQiHJ/0L/Ogsg==:4ohJt9PRpMsRMSbLwoNnGz8lUQM0zjyVnHOFFjZH3JxpEKnh274Cq2xT32ATsIFh2QJJEmm8ZMqp4P7HnHt90w==)";
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

  assertions = [
    {
      # do not let qbittorrent run if we aren't sure we've quarantined it to the network namespace
      # that is running behind the VPN
      assertion = config.systemd.services ? qbittorrent;
      message = "systemd service 'qbittorrent' not found - the qbittorrent service name may have changed";
    }
  ];

  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "qbtvpn";
  };
}
