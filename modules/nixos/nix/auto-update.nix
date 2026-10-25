{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.host) flakePath;
in {
  imports = [
    ../../shared/host.nix
    ../services/mail-relay.nix
  ];

  # Trust these keys regardless of the principal Git reports.
  host.autoUpdate.allowedSigners = ''
    # YubiKey resident keys
    ${lib.concatMapStringsSep "\n" (key: "* ${key}") (import ../../../users/carmilla/ssh-keys.nix)}
  '';
  host.autoUpdate.ciSigners = ''
    # CI signing key (Forgejo Actions)
    * ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVAUGIq89EoX6Edi6iE8tghHeRqbmUmQJJJXcWfa5Nm
  '';
  # Values the flake update workflow refreshes besides flake.lock.
  host.autoUpdate.ciPins = {
    "modules/nixos/services/caddy.nix" = ''^      hash = "sha256-[A-Za-z0-9+/]{43}=";$'';
    "hosts/sparkle/guests/homeassistant/default.nix" = "home-assistant/home-assistant@sha256:[a-f0-9]{64}";
  };

  system.autoUpgrade = {
    enable = true;
    # The upgrade script expands $rev to the verified commit below.
    flake = "git+file://${flakePath}?rev=$rev";
    allowReboot = lib.mkDefault true;
    upgrade = false;
    dates = "04:00";
    randomizedDelaySec = "15min";
    persistent = true;
  };

  # Holds the last deployed commit, which only root can change.
  systemd.services.nixos-upgrade.serviceConfig.StateDirectory = "nixos-upgrade";
  systemd.services.nixos-upgrade.script = let
    inherit (config.host.autoUpdate) owner branch;
    allowedSigners = pkgs.writeText "git-allowed-signers" config.host.autoUpdate.allowedSigners;
    ciSigners = pkgs.writeText "git-ci-signers" config.host.autoUpdate.ciSigners;
    deployedRev = "/var/lib/nixos-upgrade/deployed-rev";
    jq = "${pkgs.jq}/bin/jq";
    # Joined at the indentation of the case arms they sit among.
    ciPinCases =
      lib.concatStringsSep "\n      " (lib.mapAttrsToList (path: pattern: ''${lib.escapeShellArg path}) same_except "''${parents[1]}" "$1" "$path" ${lib.escapeShellArg pattern} ;;'')
        config.host.autoUpdate.ciPins);
    # origin/${branch} must contain the deployed commit, so history cannot be rewritten or rolled back.
    # From the tip, CI-signed commits are walked back to a trusted commit or the deployed one; a trusted signature covers the commit's whole history.
    # A CI commit may only move flake inputs forward on their existing sources, or change the values in host.autoUpdate.ciPins.
    verifyOriginBranch = pkgs.writeShellScript "verify-origin-${branch}" ''
      set -euo pipefail
      export HOME=/home/${owner}
      git() { ${pkgs.util-linux}/bin/runuser -u ${owner} -- ${pkgs.gitMinimal}/bin/git -C ${flakePath} "$@"; }

      refuse() {
        echo "refusing to upgrade: $*" >&2
        exit 1
      }

      signed_by() {
        git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile="$2" -c gpg.ssh.program=${pkgs.openssh}/bin/ssh-keygen verify-commit "$1" 2> /dev/null
      }

      # Fails unless the file differs between the commits only in text matching the pattern.
      # awk reads the pattern from the environment so backslashes reach it unchanged.
      same_except() {
        local before after
        before=$(git show "$1:$3" | pattern=$4 ${pkgs.gawk}/bin/awk '{ gsub(ENVIRON["pattern"], "PINNED") } 1')
        after=$(git show "$2:$3" | pattern=$4 ${pkgs.gawk}/bin/awk '{ gsub(ENVIRON["pattern"], "PINNED") } 1')
        [ "$before" = "$after" ] || refuse "CI commit $2 changes $3 beyond its pinned value"
      }

      # Keep the dependency graph and sources fixed; only locked versions may advance.
      check_lock() {
        ${jq} -e -n --slurpfile old <(git show "$1:flake.lock") --slurpfile new <(git show "$2:flake.lock") '
          def structure: del(.nodes) + {nodes: (.nodes | map_values(del(.locked)))};
          def source: del(.rev, .narHash, .lastModified, .revCount);
          ($old | length) == 1 and ($new | length) == 1 and (
          $old[0] as $old | $new[0] as $new |
          ($old | structure) == ($new | structure)
          and all($new.nodes | to_entries[];
            .key as $key | .value.locked as $next | $old.nodes[$key].locked as $prev
            | ($prev | source) == ($next | source)
            and ($prev == $next or (
              ($prev.lastModified | type) == "number"
              and ($next.lastModified | type) == "number"
              and $prev.lastModified <= $next.lastModified))))
        ' > /dev/null || refuse "CI commit $2 changes a flake input source or moves an input back"
      }

      check_ci_commit() {
        local parents changes status path
        read -ra parents <<< "$(git rev-list --parents -n 1 "$1")"
        [ "''${#parents[@]}" -eq 2 ] || refuse "CI commit $1 does not have exactly one parent"
        [ -z "$(git diff --no-renames --summary "''${parents[1]}" "$1")" ] || refuse "CI commit $1 changes file modes or types"
        changes=$(git diff --no-renames --name-status "''${parents[1]}" "$1")
        while IFS=$'\t' read -r status path; do
          [ -n "$status" ] || continue
          [ "$status" = M ] || refuse "CI commit $1 adds, deletes, or retypes $path"
          case $path in
            flake.lock) check_lock "''${parents[1]}" "$1" ;;
            ${ciPinCases}
            *) refuse "CI commit $1 changes $path" ;;
          esac
        done <<< "$changes"
      }

      git fetch --prune origin ${branch}
      rev=$(git rev-parse "origin/${branch}^{commit}")

      deployed=
      if [ -e ${deployedRev} ]; then
        deployed=$(${pkgs.coreutils}/bin/cat ${deployedRev})
        [[ $deployed =~ ^[0-9a-f]{40}$ ]] || refuse "invalid deployed commit in ${deployedRev}"
      fi
      if [ -n "$deployed" ] && ! git merge-base --is-ancestor "$deployed" "$rev"; then
        refuse "origin/${branch} $rev does not contain the deployed commit $deployed"
      fi

      commit=$rev
      until [ "$commit" = "$deployed" ] || signed_by "$commit" ${allowedSigners}; do
        signed_by "$commit" ${ciSigners} || refuse "$commit is not signed by a trusted key"
        check_ci_commit "$commit"
        commit=$(git rev-parse "$commit^")
      done

      git reset --hard "$rev" > /dev/null
      printf '%s\n' "$rev"
    '';
  in
    lib.mkMerge [
      (lib.mkBefore ''
        rev=$(${verifyOriginBranch})
      '')
      # Reached only after the rebuild succeeds.
      (lib.mkAfter ''
        printf '%s\n' "$rev" > ${deployedRev}.tmp
        ${pkgs.coreutils}/bin/mv -f ${deployedRev}.tmp ${deployedRev}
      '')
    ];

  systemd.services.nixos-upgrade.onFailure = ["nixos-upgrade-failed.service"];
  systemd.services.nixos-upgrade-failed = {
    serviceConfig.Type = "oneshot";
    script = ''
      {
        printf 'Subject: ${config.networking.hostName}: nixos-upgrade failed\n\n'
        ${config.systemd.package}/bin/journalctl -u nixos-upgrade -n 50 --no-pager
      } | ${config.programs.msmtp.package}/bin/sendmail carmilla@lunaire.eu
    '';
  };

  environment.etc."gitconfig".text = ''
    [safe]
    directory = ${flakePath}
  '';
}
