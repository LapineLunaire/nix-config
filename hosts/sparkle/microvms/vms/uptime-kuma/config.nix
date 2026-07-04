{...}: let
  net = import ../../vm-net.nix;
in {
  microvm = {
    vcpu = 2;
    mem = 1024;
    initialBalloonMem = 256;
    shares = [
      {
        tag = "state";
        source = "/persist/vms/uptime-kuma";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = net.ip.uptime-kuma;
      PORT = "3001";
    };
  };
  # Only Caddy (10.28.34.1) may reach the web UI.
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 3001 accept
  '';
}
