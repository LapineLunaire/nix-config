{...}: let
  net = import ../../vm-net.nix;
in {
  microvm = {
    vcpu = 4;
    mem = 6144;
    initialBalloonMem = 2048;
    shares = [
      {
        tag = "acme-cert";
        source = "/persist/var/lib/acme/unifi.lunaire.moe";
        mountPoint = "/run/acme-cert";
        proto = "virtiofs";
      }
    ];
    # Dedicated XFS volume for podman; overlayfs can't run on virtiofs.
    volumes = [
      {
        image = "/persist/vms/unifi/volumes/podman.img";
        size = 10240;
        mountPoint = "/var/lib/containers";
        fsType = "xfs";
      }
    ];
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  services.unifi-os-server = {
    enable = true;
    # Advertised to UniFi devices as the inform address; vm-br0 is routed (no NAT), so devices reach the VM directly.
    uosSystemIP = net.vmAddress.unifi;
    # No reverse proxy; serve the UI straight on 443 with the real cert installed into unifi-core (see unifi-core-cert below).
    ports.ui = 443;
    # The host forward chain source-scopes ingress (see microvms/network.nix), so the module's firewall openers stay off.
    openFirewallUiPort = false;
    openFirewallServicePorts = false;
  };

  # The host obtains the unifi.lunaire.moe cert via DNS-01 and shares its acme dir read-only at /run/acme-cert.
  # unifi-core reads unifi-core.crt/.key on start and rewrites them to a self-signed cert on an in-container restart, so the swap runs while the container is stopped.
  # unifi-core rewrites the on-disk cert, so change detection hashes the source cert.
  # The timer reimports on renewal.
  systemd.services.unifi-core-cert = {
    description = "Install ACME cert into unifi-core";
    after = ["podman-unifi-os-server.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      src=/run/acme-cert
      dst=/var/lib/unifi-os-server/data/unifi-core/config
      stamp=/var/lib/unifi-os-server/acme-imported.sum
      [ -f "$src/fullchain.pem" ] || exit 0
      sum=$(sha256sum "$src/fullchain.pem" | cut -d' ' -f1)
      [ "$sum" = "$(cat "$stamp" 2>/dev/null)" ] && exit 0
      systemctl stop podman-unifi-os-server.service
      install -Dm640 "$src/fullchain.pem" "$dst/unifi-core.crt"
      install -Dm640 "$src/key.pem" "$dst/unifi-core.key"
      systemctl start podman-unifi-os-server.service
      echo "$sum" > "$stamp"
    '';
  };
  systemd.timers.unifi-core-cert = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
