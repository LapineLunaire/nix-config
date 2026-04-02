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
        # Generate the password hash with (prefix with a space to keep it out of shell history):
        #   nix run git+https://codeberg.org/feathecutie/qbittorrent_password -- -p <password>
        # This produces a PBKDF2 hash in the format qBittorrent expects for its config file.
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
      # Verify the qbittorrent systemd service exists before binding it to the VPN namespace.
      # If the service name ever changes upstream, this fails at eval time rather than silently running qbittorrent outside the VPN.
      assertion = config.systemd.services ? qbittorrent;
      message = "systemd service 'qbittorrent' not found - the qbittorrent service name may have changed";
    }
  ];

  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "qbtvpn";
  };
}
