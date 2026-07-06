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

  system.autoUpgrade.allowReboot = false;
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPost = restartGuests;
}
