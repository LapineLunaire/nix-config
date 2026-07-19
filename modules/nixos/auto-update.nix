# Daily auto-update on top of system.autoUpgrade: an ExecStartPre verifies the origin branch head against the trusted signers before the module builds and switches. allowReboot defaults on to reboot on kernel changes, and hosts can override it.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.site.autoUpdate) repo owner branch;
  allowedSigners = pkgs.writeText "git-allowed-signers" config.site.autoUpdate.allowedSigners;
  verifyOriginMain = pkgs.writeShellScript "verify-origin-${branch}" ''
    set -euo pipefail
    export HOME=/home/${owner}
    # Run git as the checkout's owner, not root.
    git() { ${pkgs.util-linux}/bin/runuser -u ${owner} -- ${pkgs.gitMinimal}/bin/git -C ${repo} "$@"; }

    git fetch --prune origin ${branch}
    # Pin gpg.ssh.program to the ssh-keygen path instead of relying on the service PATH.
    if ! git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile=${allowedSigners} -c gpg.ssh.program=${pkgs.openssh}/bin/ssh-keygen verify-commit origin/${branch}; then
      echo "refusing to upgrade: origin/${branch} $(git rev-parse origin/${branch}) is not signed by a trusted key" >&2
      exit 1
    fi
    git reset --hard origin/${branch}
  '';
in {
  system.autoUpgrade = {
    enable = true;
    # nix builds only tracked files, which the reset above pins to the origin branch head.
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
