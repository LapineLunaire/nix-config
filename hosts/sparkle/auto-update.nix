# sparkle's auto-update: the shared signed switch with no reboot, then restarts the guests whose config the switch changed.
{
  config,
  pkgs,
  ...
}: let
  # Restart only guests whose booted runner differs from the one the switch installed.
  restartGuests = pkgs.writeShellScript "restart-microvm-guests" ''
    set -euo pipefail
    systemctl() { ${config.systemd.package}/bin/systemctl "$@"; }
    for unit in $(systemctl list-units --state=active --plain --no-legend 'microvm@*.service' | ${pkgs.gawk}/bin/awk '{print $1}'); do
      name=''${unit#microvm@}
      name=''${name%.service}
      dir=/var/lib/microvms/$name
      if [ "$(readlink -f "$dir/booted" 2>/dev/null)" != "$(readlink -f "$dir/current" 2>/dev/null)" ]; then
        systemctl restart "$unit"
      fi
    done
  '';
in {
  imports = [../../modules/nixos/auto-update.nix];

  site.autoUpdate = {
    repo = "/persist/nix-config";
    owner = "carmilla";
    branch = "main";
    # Public keys trusted to sign updates.
    allowedSigners = ''
      # YubiKey resident keys
      lapine@lunaire.eu sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU=
      lapine@lunaire.eu sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMqXDPM9z04YBOp2fVDox7sgPFNpad+9p8UA+od8V8nxAAAACnNzaDpsYXBpbmU=
      # CI signing key (Forgejo Actions)
      lapine@lunaire.eu ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINXWhax5JjCKOGESsX/udb2AKa833/9NQROV3fUUvZ9A
    '';
  };

  system.autoUpgrade.allowReboot = false;
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPost = restartGuests;
}
