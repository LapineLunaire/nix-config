{
  config,
  pkgs,
  ...
}: let
  runnerConfig = pkgs.writeText "forgejo-runner-config.yml" ''
    log:
      level: info
    runner:
      name: sparkle
      capacity: 1
      labels:
        - "docker:docker://nixos/nix:latest"
    container:
      network: host
      docker_host: "-"
  '';
in {
  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    settings = {
      server = {
        DOMAIN = "git.lunaire.moe";
        ROOT_URL = "https://git.lunaire.moe/";
        HTTP_PORT = 3000;
      };
      service.DISABLE_REGISTRATION = true;
      actions.ENABLED = true;
    };
  };

  virtualisation.oci-containers.containers.forgejo-runner = {
    image = "code.forgejo.org/forgejo/runner:12";
    autoStart = true;
    entrypoint = "/bin/sh";
    cmd = [
      "-c"
      ''
        if [ ! -f /data/.runner ]; then
          forgejo-runner register \
            --no-interactive \
            --instance "$FORGEJO_INSTANCE_URL" \
            --token "$TOKEN" \
            --name sparkle \
            --config /etc/forgejo-runner/config.yml
        fi
        exec forgejo-runner daemon --config /etc/forgejo-runner/config.yml
      ''
    ];
    environment = {
      FORGEJO_INSTANCE_URL = "https://git.lunaire.moe";
      DOCKER_HOST = "unix:///var/run/docker.sock";
    };
    environmentFiles = [
      config.sops.templates."forgejo-runner-token.env".path
    ];
    volumes = [
      "/persist/var/lib/forgejo-runner:/data"
      "/var/run/docker.sock:/var/run/docker.sock"
      "${runnerConfig}:/etc/forgejo-runner/config.yml:ro"
    ];
    extraOptions = [
      "--network=host"
      "--group-add=${toString config.users.groups.docker.gid}"
    ];
  };

  systemd.services."docker-forgejo-runner" = {
    after = ["forgejo.service"];
    requires = ["forgejo.service"];
  };
}
