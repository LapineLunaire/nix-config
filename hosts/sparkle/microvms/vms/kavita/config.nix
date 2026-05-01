{config, ...}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 1536;
    initialBalloonMem = 512;
    vsock.cid = 17;
    interfaces = [
      {
        type = "tap";
        id = "kavita";
        mac = "02:00:00:00:00:17";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/kavita";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
      {
        tag = "library";
        source = "/mnt/samba/misc";
        mountPoint = "/media/library";
        proto = "virtiofs";
      }
    ];
  };
  networking.hostName = "kavita";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.17";
      prefixLength = 24;
    }
  ];
  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets."kavita-token-key".path;
    settings.IpAddresses = "10.28.34.17";
  };
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 5000 accept
  '';
}
