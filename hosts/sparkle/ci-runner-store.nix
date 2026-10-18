{pkgs, ...}: let
  volume = "/persist/vms/ci-runner/volumes/nix-store.img";
  # Discard the database with the store so it cannot advertise missing paths.
  database = "/persist/vms/ci-runner/nix/var";
in {
  systemd.services.ci-runner-store-reset = {
    description = "Recreate the ci-runner store volume";
    # Reset before the nightly update workflows. Missed resets wait until tomorrow.
    startAt = "00:00";
    path = [pkgs.coreutils pkgs.systemd];
    serviceConfig.Type = "oneshot";
    script = ''
      systemctl stop microvm@ci-runner
      rm -rf ${database}
      rm -f ${volume}
      systemctl start --no-block microvm@ci-runner
    '';
  };
}
