{
  config,
  net,
  web,
  ...
}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 1536;
    initialBalloonMem = 512;
  };

  # Keep the absolute library paths recorded in Kavita's database.
  fileSystems."/media/library" = {
    device = "${net.vmAddress.vault}:/vault/misc/library";
    fsType = "nfs4";
    options = [
      "ro"
      "nosuid"
      "nodev"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.mount-timeout=20"
      "x-systemd.idle-timeout=600"
      "noatime"
    ];
  };

  # Metadata fetches and SMTP.
  microvmGuest.egress = [
    {
      proto = "tcp";
      ports = [80 443 587];
    }
  ];

  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets."kavita-token-key".path;
    settings = {
      IpAddresses = net.vmAddress.kavita;
      Port = web.endpoints.kavita.port;
    };
  };
}
