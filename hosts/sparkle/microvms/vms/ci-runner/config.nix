{
  config,
  pkgs,
  ...
}: {
  imports = [./sops.nix];

  microvm = {
    vcpu = 8;
    mem = 12288;
    initialBalloonMem = 4096;
    vsock.cid = 13;
    interfaces = [
      {
        type = "tap";
        id = "ci-runner";
        mac = "02:00:00:00:00:13";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/ci-runner";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
    # Dedicated XFS volume for Docker — overlayfs can't run on virtiofs.
    volumes = [
      {
        image = "/persist/vms/ci-runner/volumes/docker.img";
        size = 20480;
        mountPoint = "/var/lib/docker";
        fsType = "xfs";
      }
    ];
  };
  networking.hostName = "ci-runner";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.28.34.13";
      prefixLength = 24;
    }
  ];

  virtualisation.docker.enable = true;

  sops.templates."runner-token.env".content = ''
    TOKEN=${config.sops.placeholder."forgejo-runner-token"}
  '';

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.sparkle = {
      enable = true;
      name = "sparkle";
      url = "https://git.lunaire.moe";
      tokenFile = config.sops.templates."runner-token.env".path;
      labels = ["debian:docker://node:25@sha256:c69f4e0640e5b065f2694579793e4309f1e0e49868b0f2fea29c44d9c0dc2caf"];
      settings = {
        runner.capacity = 2;
        container = {
          network = "bridge";
          docker_host = "-";
          pull_policy = "if-not-present";
        };
      };
    };
  };

  systemd.services.gitea-runner-sparkle.serviceConfig.SupplementaryGroups = ["docker"];
}
