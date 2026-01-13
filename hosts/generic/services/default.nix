{...}: {
  imports = [
    ./greetd.nix
    ./openssh.nix
    ./pipewire.nix
  ];

  services.fstrim.enable = true;
  services.fwupd.enable = true;

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  services.smartd.enable = true;
}
