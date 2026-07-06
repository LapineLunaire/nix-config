{
  lib,
  outputs,
  ...
}: let
  vms = import ./vm-registry.nix;
in {
  imports = [./network.nix];

  # Offer sparkle's host key when microvm -s connects to a guest as root over VSOCK; guests authorize it for root (see guest.nix).
  programs.ssh.extraConfig = ''
    Host vsock/* vsock-mux/*
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
  '';

  microvm.vms =
    lib.mapAttrs (name: _: {
      autostart = true;
      evaluatedConfig = outputs.nixosConfigurations.${name};
    })
    vms;

  # Attach each VM's tap interface to the bridge.
  systemd.network.networks = lib.mapAttrs' (name: _:
    lib.nameValuePair "10-${name}" {
      matchConfig.Name = name;
      networkConfig.Bridge = "vm-br0";
    })
  vms;

  # Start VMs after the ones they depend on.
  systemd.services = lib.mapAttrs' (name: vm:
    lib.nameValuePair "microvm@${name}" {
      after = map (dep: "microvm@${dep}.service") (vm.deps or []);
      wants = map (dep: "microvm@${dep}.service") (vm.deps or []);
    })
  vms;
}
