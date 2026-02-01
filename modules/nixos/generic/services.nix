{...}: {
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
