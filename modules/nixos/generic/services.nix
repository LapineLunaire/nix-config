{...}: {
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # NTS = authenticated NTP, prevents time spoofing
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
    # ed25519 only — sops-nix derives age keys from this host key
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
