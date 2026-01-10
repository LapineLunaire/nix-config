# NTS provides authenticated, encrypted time synchronization
{...}: {
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };
}
