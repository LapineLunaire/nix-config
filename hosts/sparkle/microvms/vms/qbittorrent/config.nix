{config, ...}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 1024;
    initialBalloonMem = 256;
    vsock.cid = 15;
    interfaces = [
      {
        type = "tap";
        id = "qbittorrent";
        mac = "02:00:00:00:00:15";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/qbittorrent";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
      {
        tag = "torrents";
        source = "/mnt/samba/torrents";
        mountPoint = "/mnt/samba/torrents";
        proto = "virtiofs";
      }
    ];
  };
  networking.hostName = "qbittorrent";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.15";
      prefixLength = 24;
    }
  ];

  vpnNamespaces.qbtvpn = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."protonvpn-qbittorrent-conf".path;
    accessibleFrom = ["10.28.34.1/32"];
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
      assertion = config.systemd.services ? qbittorrent;
      message = "systemd service 'qbittorrent' not found — the service name may have changed upstream";
    }
  ];

  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "qbtvpn";
  };

  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 4000 accept
  '';
}
