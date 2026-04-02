{...}: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "sparkle";
        "netbios name" = "sparkle";
        "security" = "user";
        # Allow 10.0.0.0/8 and loopback. Deny everything else.
        "hosts allow" = "10.0.0.0/8 127.0.0.0/8 ::1";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "never";
      };
      carmilla = {
        "path" = "/mnt/samba/carmilla";
        "valid users" = "carmilla";
        "writeable" = "yes";
        "force user" = "carmilla";
        "force group" = "users";
        "create mask" = "0644";
        "directory mask" = "0755";
        # Fruit VFS module: macOS compatibility for extended attributes and metadata.
        "fruit:aapl" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
      misc = {
        "path" = "/mnt/samba/misc";
        "valid users" = "carmilla";
        "writeable" = "no";
        "force user" = "carmilla";
        "force group" = "users";
        "fruit:aapl" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
      torrents = {
        "path" = "/mnt/samba/torrents";
        "valid users" = "carmilla";
        "writeable" = "no";
        "fruit:aapl" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  # wsdd makes the server discoverable in Windows Network without NetBIOS.
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
