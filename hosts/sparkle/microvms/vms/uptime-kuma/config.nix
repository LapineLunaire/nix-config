{...}: let
  net = import ../../vm-net.nix;
in {
  microvm = {
    vcpu = 2;
    mem = 1024;
    initialBalloonMem = 256;
  };
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = net.ip.uptime-kuma;
      PORT = "3001";
    };
  };
  microvmGuest.hostIngressTCPPorts = [3001];
}
