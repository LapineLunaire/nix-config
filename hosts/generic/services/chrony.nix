{...}: {
  # NTS = authenticated, encrypted time sync
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };
}
