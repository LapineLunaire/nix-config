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
  imports = [../../../../modules/nixos/nix/attic-client.nix];

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

  virtualisation.docker.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  # The runner token from registration, not the registration token.
  sops.secrets."forgejo-runner-token".restartUnits = ["forgejo-runner-sparkle.service"];

  systemd.services.forgejo-runner-sparkle = {
    path = [config.virtualisation.docker.package];
    serviceConfig = {
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

  services.forgejo-runner.instances.sparkle = {
    enable = true;
    secrets.server.connections.default.token_url = config.sops.secrets."forgejo-runner-token".path;
    settings = {
      server.connections.default = {
        url = web.origin.forgejo;
        uuid = "331cacbe-4bbf-4b7f-95aa-996f48a63293";
      };
      runner = {
        labels = ["nixos:docker://${image.imageName}:${image.imageTag}"];
        capacity = 1;
        timeout = "6h";
      };
      container = {
        # Jobs read the guest's own cache credential. Docker reads the root-only file for each new job, so a new
        # token needs no runner restart; unsandboxed nixbld users cannot read the mount.
        options = "--mount type=bind,source=${config.sops.templates."nix-netrc".path},target=/etc/nix/netrc,readonly";
        valid_volumes = [config.sops.templates."nix-netrc".path];
      };
      cache.enabled = false;
    };
  };
}
