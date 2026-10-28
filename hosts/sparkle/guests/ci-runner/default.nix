{
  config,
  lib,
  pkgs,
  web,
  ...
}: let
  image = import ./image.nix {
    inherit pkgs;
    extraSubstituters = config.nix.settings.extra-substituters;
    extraTrustedPublicKeys = config.nix.settings.extra-trusted-public-keys;
  };
in {
  imports = [../../../../modules/nixos/nix/server-cache.nix ./sops.nix];

  microvm = let
    swapImage = "/persist/volumes/ci-runner/swap.img";
  in {
    vcpu = 8;
    mem = 20480;
    initialBalloonMem = 0;
    volumes = [
      {
        image = "/persist/volumes/ci-runner/docker.img";
        size = 196608;
        mountPoint = "/var/lib/docker";
        fsType = "xfs";
      }
      # Create raw swap on the host; microvm's filesystem creator cannot format it.
      {
        image = swapImage;
        mountPoint = null;
        autoCreate = false;
      }
    ];
    # Create swap before cloud-hypervisor opens it, including on a fresh host.
    preStart = ''
      if [ ! -e ${swapImage} ]; then
        ${pkgs.coreutils}/bin/truncate -s 32768M ${swapImage}
        ${pkgs.util-linux}/bin/mkswap -L ci-swap ${swapImage}
      fi
    '';
  };

  # Jobs can fetch dependencies from arbitrary public endpoints.
  microvmGuest.egress = [
    {proto = "tcp";}
    {proto = "udp";}
    {proto = "icmp";}
  ];

  # Use disk swap after zram. Labels survive changes in disk declaration order.
  swapDevices = [{label = "ci-swap";}];

  nix.settings = {
    extra-substituters = lib.mkAfter ["https://cache.lunaire.moe/desktop?priority=10"];
    extra-trusted-public-keys = lib.mkAfter ["desktop:QBHQfUrDyPKWwQolz4KiaJ1NlC+dGZLP4m29qgvkYs4="];
  };

  virtualisation.docker.enable = true;

  sops.templates."runner-token.env" = {
    restartUnits = ["gitea-runner-sparkle.service"];
    content = ''
      TOKEN=${config.sops.placeholder."forgejo-runner-token"}
    '';
  };

  sops.templates."runner-cache.env" = {
    restartUnits = ["gitea-runner-sparkle.service"];
    content = ''
      ATTIC_PULL_TOKEN=${config.sops.placeholder."attic-pull-token"}
    '';
  };

  systemd.services.gitea-runner-sparkle = {
    path = [config.virtualisation.docker.package];
    serviceConfig = {
      LoadCredential = ["cache.env:${config.sops.templates."runner-cache.env".path}"];
      # Docker here only runs CI, so clear what interrupted jobs left and load the image before every runner start.
      ExecStartPre = lib.mkBefore [
        (pkgs.writeShellScript "ci-runner-prepare" ''
          set -euo pipefail
          docker container ls --all --quiet | xargs --no-run-if-empty docker container rm --force --volumes
          docker volume prune --all --force
          docker network prune --force
          docker load --input ${image}
          docker image prune --force
        '')
      ];
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.sparkle = {
      enable = true;
      name = "sparkle";
      url = web.origin.forgejo;
      tokenFile = config.sops.templates."runner-token.env".path;
      labels = ["nixos:docker://${image.imageName}:${image.imageTag}"];
      settings = {
        runner = {
          capacity = 1;
          timeout = "6h";
          env_file = "/run/credentials/gitea-runner-sparkle.service/cache.env";
        };
        cache.enabled = false;
      };
    };
  };
}
