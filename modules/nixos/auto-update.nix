# Daily auto-update on top of system.autoUpgrade: an ExecStartPre verifies origin/main against the trusted signers before the module builds and switches. allowReboot defaults on to reboot on kernel changes, and hosts can override it.
{
  lib,
  pkgs,
  ...
}: let
  repo = "/persist/nix-config";
  branch = "main";
  allowedSigners = ./git-allowed-signers;
  verifyOriginMain = pkgs.writeShellScript "verify-origin-main" ''
    set -euo pipefail
    git() { ${pkgs.gitMinimal}/bin/git -C ${repo} "$@"; }

    git fetch --prune origin ${branch}
    if ! git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile=${allowedSigners} verify-commit origin/${branch}; then
      echo "refusing to upgrade: origin/${branch} $(git rev-parse origin/${branch}) is not signed by a trusted key" >&2
      exit 1
    fi
    git reset --hard origin/${branch}
  '';
in {
  system.autoUpgrade = {
    enable = true;
    # nix builds only tracked files, which the reset above pins to origin/main.
    flake = repo;
    allowReboot = lib.mkDefault true;
    upgrade = false;
    dates = "03:00";
    randomizedDelaySec = "15min";
    persistent = true;
  };

  systemd.services.nixos-upgrade.serviceConfig.ExecStartPre = verifyOriginMain;

  # The upgrade runs git and nix's flake fetcher as root against this user-owned checkout; trust the path so neither refuses it.
  environment.etc."gitconfig".text = ''
    [safe]
    directory = ${repo}
  '';
}
