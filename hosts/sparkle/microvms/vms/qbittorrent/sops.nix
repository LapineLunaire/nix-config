{...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."protonvpn-qbittorrent-conf" = {};
    # Read by the unprivileged ExecStartPre in config.nix that splices it into qBittorrent.conf.
    secrets."qbittorrent-webui-password-hash" = {
      owner = "qbittorrent";
      restartUnits = ["qbittorrent.service"];
    };
  };
}
