{
  config,
  net,
  web,
  ...
}: {
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

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."kavita-token-key".restartUnits = ["kavita.service"];

  services.kavita = {
    enable = true;
    # Fills the default TokenKey placeholder, @token_key@, when the service starts.
    credentials.token_key = config.sops.secrets."kavita-token-key".path;
    settings = {
      IpAddresses = net.vmAddress.kavita;
      Port = web.endpoints.kavita.port;
    };
  };
}
