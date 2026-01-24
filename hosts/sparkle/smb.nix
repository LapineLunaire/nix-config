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
        "hosts allow" = "10.0.0.0/8 127.0.0.0/8 ::1";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      lapine = {
        "path" = "/mnt/samba/lapine";
        "valid users" = "lapine";
        "writeable" = "yes";
        "force user" = "lapine";
        "force group" = "users";
        "create mask" = "0644";
        "directory mask" = "0755";
        "fruit:aapl" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
      torrents = {
        "path" = "/mnt/samba/torrents";
        "valid users" = "lapine";
        "writeable" = "no";
        "fruit:aapl" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
