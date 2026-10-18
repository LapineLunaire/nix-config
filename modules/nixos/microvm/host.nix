{
  lib,
  dmz,
  guestRegistry,
  guestConfigurations,
  ...
}: let
  registry = guestRegistry;
in {
  programs.ssh.extraConfig = ''
    Host vsock/* vsock-mux/*
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
  '';

  microvm.vms =
    lib.mapAttrs (name: _: {
      autostart = true;
      evaluatedConfig = guestConfigurations.${name};
    })
    registry;

  # microvm.nix creates share roots, but its image formatter does not create parent directories.
  systemd.tmpfiles.settings."20-microvm-volumes" =
    lib.genAttrs (
      lib.unique (lib.concatMap (name:
        map (volume: builtins.dirOf volume.image) guestConfigurations.${name}.config.microvm.volumes)
      (lib.attrNames registry))
    ) (_: {
      d = {
        user = "microvm";
        group = "kvm";
        mode = "0750";
      };
    });

  systemd.network.networks = lib.mapAttrs' (name: _:
    lib.nameValuePair "20-vm-${name}" {
      matchConfig.Name = name;
      networkConfig.Bridge = dmz.bridge;
    })
  registry;

  systemd.services = lib.mapAttrs' (name: vm:
    lib.nameValuePair "microvm@${name}" {
      after = map (dep: "microvm@${dep}.service") (vm.deps or []);
      wants = map (dep: "microvm@${dep}.service") (vm.deps or []);
    })
  registry;
}
