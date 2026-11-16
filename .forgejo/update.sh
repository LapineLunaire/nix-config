#!/usr/bin/env bash
set -euo pipefail

SERVER_INPUTS='nixpkgs-stable home-manager-stable nixvim-stable microvm'
HOSTS='sparkle camellya kafka'
HA_FILE=hosts/sparkle/guests/homeassistant/default.nix
CURSEFORGE_FILE=pkgs/curseforge/pin.json
CADDY_FILE=modules/nixos/services/caddy.nix

check() {
  nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
}

build() {
  nix build --no-link ".#nixosConfigurations.$1.config.system.build.toplevel"
}

# Replace exactly one match, preserving everything outside it, including the final newline.
write_pin() {
  local path=$1 replacement=$2 pattern text
  local -a matches
  pattern=$(printf '%s\n' "$CI_PINS" | jq -er --arg path "$path" '.[$path]')
  mapfile -t matches < <(grep -oE -- "$pattern" "$path")
  if [ "${#matches[@]}" -ne 1 ]; then
    echo "$path must have exactly one ciPins match" >&2
    return 1
  fi
  printf '%s\n' "$replacement" | grep -xE -- "$pattern" > /dev/null
  text=$(cat "$path" && printf '.')
  text=${text%.}
  text=${text/"${matches[0]}"/"$replacement"}
  printf '%s' "$text" > "$path"
  # The old text can also appear outside the match, so check that the match itself changed.
  if [ "$(grep -oE -- "$pattern" "$path")" != "$replacement" ]; then
    echo "$path did not take its new ciPins value" >&2
    return 1
  fi
}

update_ha() {
  if [ "$(date +%u)" != 1 ] && [ "$EVENT_NAME" != workflow_dispatch ]; then
    echo 'not Monday, skipping'
    return
  fi
  local digest
  digest=$(skopeo inspect --format '{{.Digest}}' docker://ghcr.io/home-assistant/home-assistant:stable)
  [[ $digest =~ ^sha256:[a-f0-9]{64}$ ]]
  write_pin "$HA_FILE" "home-assistant/home-assistant@$digest"
}

update_curseforge() {
  local latest version path hash old_version old_hash
  # The job image has no curl. Nix fetches the release list.
  latest=$(nix eval --impure --raw --option tarball-ttl 0 --expr 'builtins.readFile (builtins.fetchurl "https://curseforge.overwolf.com/electron/linux/latest-linux.yml")')
  version=$(printf '%s\n' "$latest" | sed -n 's/^version: //p')
  path=$(printf '%s\n' "$latest" | sed -n 's/^path: //p')
  hash=sha512-$(printf '%s\n' "$latest" | sed -n 's/^sha512: //p')
  if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]] || [[ ! $hash =~ ^sha512-[A-Za-z0-9+/]{86}==$ ]] || [ "$path" != "CurseForge-$version.AppImage" ]; then
    echo 'Unexpected CurseForge release list:' >&2
    printf '%s\n' "$latest" >&2
    return 1
  fi
  old_version=$(jq -er .version "$CURSEFORGE_FILE")
  old_hash=$(jq -er .hash "$CURSEFORGE_FILE")
  if [ "$version" = "$old_version" ] && [ "$hash" = "$old_hash" ]; then
    return
  fi
  if [ "$(printf '%s\n' "$old_version" "$version" | sort -V | tail -n 1)" != "$version" ]; then
    echo "CurseForge $version is older than $old_version, keeping the current version"
    return
  fi
  write_pin "$CURSEFORGE_FILE" "{\"version\": \"$version\", \"hash\": \"$hash\"}"
  nix build --no-link .#nixosConfigurations.camellya.pkgs.curseforge
}

refresh_caddy() {
  local err got
  # Keep this source out of the cache: this build must check the plugin hash.
  if err=$(nix build --no-link .#nixosConfigurations.proxy.config.services.caddy.package.src 2>&1); then
    return
  fi
  got=$(printf '%s\n' "$err" | sed -n 's/^ *got: *\(sha256-[A-Za-z0-9+/=]\{1,\}\).*/\1/p' | head -1)
  [[ $got =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]
  write_pin "$CADDY_FILE" "      hash = \"$got\";"
}

update_server() {
  local input before
  local -a inputs
  read -ra inputs <<< "$SERVER_INPUTS"
  for input in "${inputs[@]}"; do
    case " $INPUT_NAMES " in
      *" $input "*) ;;
      *) echo "SERVER_INPUTS names $input, which is not a flake input" >&2; return 1 ;;
    esac
  done
  before=$(git hash-object --no-filters flake.lock)
  nix flake update "${inputs[@]}"
  if [ "$(git hash-object --no-filters flake.lock)" = "$before" ]; then
    return
  fi
  refresh_caddy
  check
  build sparkle
}

update_rest() {
  local input before host
  local -a all_inputs inputs=()
  read -ra all_inputs <<< "$INPUT_NAMES"
  for input in "${all_inputs[@]}"; do
    case " $SERVER_INPUTS " in
      *" $input "*) ;;
      *) inputs+=("$input") ;;
    esac
  done
  # With no names, nix flake update updates every input.
  if [ "${#inputs[@]}" -eq 0 ]; then
    return
  fi
  before=$(git hash-object --no-filters flake.lock)
  nix flake update "${inputs[@]}"
  if [ "$(git hash-object --no-filters flake.lock)" = "$before" ]; then
    return
  fi
  check
  for host in $HOSTS; do
    build "$host"
  done
}

# A fresh Bash keeps errexit active inside update functions, even when an attempt fails.
# Git objects keep snapshots out of temporary directories that builds can write to.
attempt() {
  local problem=$1 update=$2 path status
  shift 2
  local -a snapshots=()
  for path in "$@"; do
    snapshots+=("$(git hash-object -w --no-filters "$path")")
  done
  set +e
  bash -euo pipefail "$0" --attempt "$update"
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    for path in "$@"; do
      git cat-file blob "${snapshots[0]}" > "$path"
      snapshots=("${snapshots[@]:1}")
    done
    problems+=("$problem")
  fi
}

if [ "${1:-}" = --attempt ]; then
  "$2"
  exit
fi

# Evaluate the server's patterns once, before any changes to the inputs.
export CI_PINS INPUT_NAMES
CI_PINS=$(nix eval --json --no-write-lock-file .#nixosConfigurations.sparkle.config.host.autoUpdate.ciPins)
INPUT_NAMES=$(nix eval --impure --raw --expr 'builtins.concatStringsSep " " (builtins.attrNames (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.root.inputs)')
problems=()
attempt 'The Home Assistant digest was not updated' update_ha "$HA_FILE"
attempt 'CurseForge was not updated' update_curseforge "$CURSEFORGE_FILE"
attempt 'Server inputs were not updated' update_server flake.lock "$CADDY_FILE"
attempt 'Remaining inputs were not updated' update_rest flake.lock

changed=false
paths=()
if ! git diff --quiet -- flake.lock "$CADDY_FILE" "$HA_FILE" "$CURSEFORGE_FILE"; then
  changed=true
  check
  if ! jq -e -n --slurpfile old <(git show HEAD:flake.lock) --slurpfile new flake.lock \
    -f modules/nixos/nix/ci-lock-check.jq > /dev/null; then
    problems+=('The servers will refuse the pushed commit until a trusted commit follows it; see docs/updates.md')
  fi
  # Sparkle includes every guest runner. Failure here blocks the cache upload and commit.
  failed=()
  for host in $HOSTS; do
    if out=$(nix build --no-link --print-out-paths ".#nixosConfigurations.$host.config.system.build.toplevel"); then
      paths+=("$out")
    elif [ "$host" = sparkle ]; then
      exit 1
    else
      failed+=("$host")
    fi
  done
  if [ "${#failed[@]}" -gt 0 ]; then
    problems+=("Not built or cached: ${failed[*]}")
  fi
fi

{
  echo "changed=$changed"
  echo 'paths<<UPDATE_PATHS'
  if [ "${#paths[@]}" -gt 0 ]; then printf '%s\n' "${paths[@]}"; fi
  echo UPDATE_PATHS
  echo 'problems<<UPDATE_PROBLEMS'
  if [ "${#problems[@]}" -gt 0 ]; then printf '%s\n' "${problems[@]}"; fi
  echo UPDATE_PROBLEMS
} >> "$GITHUB_OUTPUT"
