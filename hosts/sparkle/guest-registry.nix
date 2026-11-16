# One entry per Sparkle guest. Never change an index: it sets the guest's IPv4 address, VSOCK CID, and hexadecimal MAC suffix.
# - deps: guests that start first. Nothing waits for their applications to be ready.
# - web: the subdomain of guest-web.nix's domain and the port that proxy serves the guest on.
# - database: a PostgreSQL database and role named after the guest, whose password is <name>-db-password
#   in hosts/sparkle/guests/<name>/database.yaml. The guest also starts after postgres.
# - nfs: the guest may reach vault's NFS server. The exports themselves are in the vault guest.
{
  dns.index = 10;
  proxy = {
    index = 11;
    deps = ["dns"];
    nfs = true;
  };
  postgres.index = 12;
  pgadmin = {
    index = 13;
    web = {
      sub = "pga";
      port = 5000;
    };
  };
  authelia = {
    index = 14;
    database = true;
    web = {
      sub = "auth";
      port = 9091;
    };
  };
  monitoring = {
    index = 15;
    web = {
      sub = "gf";
      port = 3000;
    };
  };
  uptime-kuma = {
    index = 16;
    web = {
      sub = "up";
      port = 3001;
    };
  };
  vault.index = 17;
  attic = {
    index = 18;
    database = true;
    web = {
      sub = "cache";
      port = 8080;
    };
  };
  forgejo = {
    index = 20;
    database = true;
    web = {
      sub = "git";
      port = 3000;
    };
  };
  ci-runner = {
    index = 21;
    deps = ["forgejo"];
  };
  vaultwarden = {
    index = 22;
    database = true;
    web = {
      sub = "vw";
      port = 8222;
    };
  };
  kavita = {
    index = 23;
    nfs = true;
    web = {
      sub = "kv";
      port = 5000;
    };
  };
  qbittorrent = {
    index = 24;
    nfs = true;
    web = {
      sub = "qbt";
      port = 4000;
    };
  };
  homeassistant = {
    index = 25;
    web = {
      sub = "ha";
      port = 8123;
    };
  };
}
