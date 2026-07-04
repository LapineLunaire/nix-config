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
  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets."kavita-token-key".path;
    settings.IpAddresses = net.ip.kavita;
  };
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.34.1 tcp dport 5000 accept
  '';
}
