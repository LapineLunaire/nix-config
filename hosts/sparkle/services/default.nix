{...}: {
  imports = [
    ./coredns.nix
    ./database.nix
    ./git.nix
    ./homeassistant.nix
    ./iperf3.nix
    ./proxy.nix
    ./qbittorrent.nix
    ./smb.nix
    ./vaultwarden.nix
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };
  virtualisation.oci-containers.backend = "podman";
}
