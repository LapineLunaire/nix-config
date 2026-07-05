{config, ...}: let
  net = import ../../vm-net.nix;
in {
  imports = [./sops.nix];

  microvm = {
    vcpu = 2;
    mem = 1536;
    initialBalloonMem = 512;
    shares = [
      {
        tag = "library";
        source = "/mnt/samba/misc";
        mountPoint = "/media/library";
        proto = "virtiofs";
      }
    ];
  };
  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets."kavita-token-key".path;
    settings.IpAddresses = net.vmAddress.kavita;
  };
  microvmGuest.hostIngressTCPPorts = [5000];
}
