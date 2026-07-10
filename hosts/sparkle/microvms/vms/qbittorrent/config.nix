{
  config,
  lib,
  pkgs,
  ...
}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 1024;
    initialBalloonMem = 256;
    shares = [
      {
        tag = "torrents";
        source = "/mnt/samba/torrents";
        mountPoint = "/mnt/samba/torrents";
        proto = "virtiofs";
      }
    ];
  };

  vpnNamespaces.qbtvpn = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."protonvpn-qbittorrent-conf".path;
    accessibleFrom = ["${net.hostAddress}/32"];
    portMappings = [
      {
        from = 4000;
        to = 4000;
        protocol = "tcp";
      }
    ];
    # 57140 is the port ProtonVPN forwards to this WireGuard config; update it here and in torrentingPort below if the assignment changes.
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
        # Placeholder in the store-rendered config; the ExecStartPre below swaps it for the sops-held hash after the module installs the file.
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

  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "qbtvpn";
  };

  # Runs after the module's ExecStartPre installs the rendered config (mkAfter), as the qbittorrent user like the rest of the unit.
  systemd.services.qbittorrent.serviceConfig.ExecStartPre = lib.mkAfter [
    "${pkgs.replace-secret}/bin/replace-secret '@WEBUI_PASSWORD_PBKDF2@' ${config.sops.secrets."qbittorrent-webui-password-hash".path} /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
  ];

  microvmGuest.hostIngressTCPPorts = [4000];
}
