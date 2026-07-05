# Shared Docker config for the microVMs that run containers (homeassistant, ci-runner, pgadmin).
# Container stdout/stderr goes to the journal instead of unbounded json-file logs on the small docker.img volume.
# /var/log is persisted to the host ZFS pool (see guest.nix), so logs survive reboots and stay off the volume; `journalctl CONTAINER_NAME=<name>` and `docker logs` both read them back.
{...}: {
  virtualisation.docker = {
    enable = true;
    daemon.settings.log-driver = "journald";

    # Weekly `docker system prune`. --all also reclaims superseded images: refs are pinned by digest, so a bumped digest (via the container-update workflow) leaves the old image unused-but-tagged, which a plain dangling-only prune never removes.
    # Running containers' images are kept; volumes are untouched (no --volumes), so bind-mounted state is safe.
    autoPrune = {
      enable = true;
      flags = ["--all"];
    };
  };
  virtualisation.oci-containers.backend = "docker";
}
