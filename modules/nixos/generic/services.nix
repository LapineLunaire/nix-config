{...}: {
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # NTS (RFC 8915): TLS-authenticated NTP, prevents on-path attackers from spoofing time responses.
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
    # Only ed25519 host keys are enabled. sops-nix derives its age decryption key from this host key.
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
