{
  config,
  inputs,
  ...
}: {
  imports = [./sops.nix ../docker-common.nix];

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

  sops.templates."runner-token.env".content = ''
    TOKEN=${config.sops.placeholder."forgejo-runner-token"}
  '';

  services.gitea-actions-runner = {
    package = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.forgejo-runner;
    instances.sparkle = {
      enable = true;
      name = "sparkle";
      url = "https://git.lunaire.moe";
      tokenFile = config.sops.templates."runner-token.env".path;
      labels = ["debian:docker://node:25@sha256:78839ac448c23517f8eab2e8f7943d9b4f73979eb7f8bed2c73dbf72ff869e7b"];
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
