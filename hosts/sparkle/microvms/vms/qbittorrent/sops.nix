{...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."protonvpn-qbittorrent-conf" = {};
  };
}
