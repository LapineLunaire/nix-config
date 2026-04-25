{...}: {
  microvm = {
    vcpu = 2;
    mem = 1024;
    initialBalloonMem = 256;
    vsock.cid = 18;
    interfaces = [
      {
        type = "tap";
        id = "uptime-kuma";
        mac = "02:00:00:00:00:18";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/uptime-kuma";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };
  networking.hostName = "uptime-kuma";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.18";
      prefixLength = 24;
    }
  ];
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "0.0.0.0";
      PORT = "3001";
    };
  };
  # Only Caddy (10.28.34.1) may reach the web UI.
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 3001 accept
  '';
}
