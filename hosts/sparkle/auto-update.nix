# sparkle's auto-update: the shared signed switch, but no reboot and a guest restart afterwards, since a host switch leaves running microVMs on their old config.
{
  config,
  pkgs,
  ...
}: let
  restartGuests = pkgs.writeShellScript "restart-microvm-guests" ''
    set -euo pipefail
    systemctl() { ${config.systemd.package}/bin/systemctl "$@"; }
    units=$(systemctl list-units --plain --no-legend 'microvm@*.service' | ${pkgs.gawk}/bin/awk '{print $1}')
    if [ -n "$units" ]; then
      systemctl restart $units
    fi
  '';
in {
  imports = [../../modules/nixos/auto-update.nix];

  system.autoUpgrade.allowReboot = false;
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPost = restartGuests;
}
