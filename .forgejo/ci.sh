#!/usr/bin/env bash
# The update and validation workflows run their steps from here: ci.sh <command>.
set -euo pipefail

# The runner cannot build Sparxie or Silverwolf.
HOSTS='sparkle camellya kafka'
CACHE=https://cache.lunaire.moe/lune
HA_FILE=hosts/sparkle/guests/homeassistant/default.nix
CURSEFORGE_FILE=pkgs/curseforge/pin.json
CADDY_FILE=modules/nixos/services/caddy.nix

# Without the runner's credential, Nix builds from source instead of failing.
check_cache() {
  nix store info --store "$CACHE" > /dev/null
}

format() {
  nix fmt --no-write-lock-file -- --check .
}

check() {
  nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
}

# Build a host and print its store path.
build() {
  nix build --no-link --print-out-paths ".#nixosConfigurations.$1.config.system.build.toplevel"
}

build_uncached() {
  local host attr out
  for host in $HOSTS; do
    attr=".#nixosConfigurations.$host.config.system.build.toplevel"
    out=$(nix eval --raw --no-write-lock-file "$attr.outPath")
    if nix path-info --store "$CACHE" "$out" > /dev/null 2>&1; then
      echo "$host is unchanged from a cached system: $out"
      continue
    fi
    nix build --no-link --no-write-lock-file "$attr"
  done
}

# The update rewrites these values, and the servers accept a CI commit only where the pattern matches.
load_pins() {
  export CI_PINS
  CI_PINS=$(nix eval --json --no-write-lock-file .#nixosConfigurations.sparkle.config.host.autoUpdate.ciPins)
}

pin_paths() {
  printf '%s\n' "$CI_PINS" | jq -er 'keys[]'
}

# Print the text that the path's pattern matches, which must be in one place only.
pin_match() {
  local path=$1 pattern
  local -a matches
  pattern=$(printf '%s\n' "$CI_PINS" | jq -er --arg path "$path" '.[$path]')
  mapfile -t matches < <(grep -oE -- "$pattern" "$path")
  if [ "${#matches[@]}" -ne 1 ]; then
    echo "$path has ${#matches[@]} matches of its ciPins pattern instead of one" >&2
    return 1
  fi
  printf '%s\n' "${matches[0]}"
}

check_pins() {
  local paths path
  paths=$(pin_paths)
  for path in $paths; do
    pin_match "$path" > /dev/null
  done
}

# Replace the match, preserving everything outside it, including the final newline.
write_pin() {
  local path=$1 replacement=$2 pattern old text
  pattern=$(printf '%s\n' "$CI_PINS" | jq -er --arg path "$path" '.[$path]')
  old=$(pin_match "$path")
  printf '%s\n' "$replacement" | grep -xE -- "$pattern" > /dev/null
  text=$(cat "$path" && printf '.')
  text=${text%.}
  text=${text/"$old"/"$replacement"}
  printf '%s' "$text" > "$path"
  # The old text can also appear outside the match, so check that the match itself changed.
  if [ "$(pin_match "$path")" != "$replacement" ]; then
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
  latest=$(curl --fail --silent --show-error --location https://curseforge.overwolf.com/electron/linux/latest-linux.yml)
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

update_inputs() {
  local before host
  before=$(git hash-object --no-filters flake.lock)
  nix flake update
  if [ "$(git hash-object --no-filters flake.lock)" = "$before" ]; then
    return
  fi
  refresh_caddy
  check
  # This is the last update, so these are the systems to push. Report them to the caller.
  for host in $HOSTS; do
    build "$host" >&3
  done
}

# A fresh Bash keeps errexit active inside update functions, even when an attempt fails.
# Git objects keep snapshots out of temporary directories that builds can write to.
# built holds the store paths that the update reported on descriptor 3, and only those of the latest attempt.
attempt() {
  local problem=$1 update=$2 path status
  shift 2
  local -a snapshots=()
  for path in "$@"; do
    snapshots+=("$(git hash-object -w --no-filters "$path")")
  done
  set +e
  built=$(bash "$0" --attempt "$update" 3>&1 >&2)
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    built=
    for path in "$@"; do
      git cat-file blob "${snapshots[0]}" > "$path"
      snapshots=("${snapshots[@]:1}")
    done
    problems+=("$problem")
  fi
}

output_list() {
  local name=$1
  shift
  echo "$name<<CI_OUTPUT"
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@"; fi
  echo CI_OUTPUT
}

update() {
  local publish=false built='' pins host out
  local -a problems=() files paths=() failed=()
  check_cache
  # Evaluate the server's patterns once, before any changes to the inputs.
  load_pins
  pins=$(pin_paths)
  mapfile -t files <<< "flake.lock"$'\n'"$pins"

  attempt 'The Home Assistant digest was not updated' update_ha "$HA_FILE"
  attempt 'CurseForge was not updated' update_curseforge "$CURSEFORGE_FILE"
  attempt 'Flake inputs were not updated' update_inputs flake.lock "$CADDY_FILE"

  if ! git diff --quiet -- "${files[@]}"; then
    publish=true
    if [ -n "$built" ]; then
      # The last update already checked and built exactly these files.
      mapfile -t paths <<< "$built"
    elif ! check; then
      publish=false
      problems+=('The combined changes failed the flake check, so nothing was pushed')
    else
      # Sparkle includes every guest runner, so nothing is pushed without it.
      for host in $HOSTS; do
        if out=$(build "$host"); then
          paths+=("$out")
        elif [ "$host" = sparkle ]; then
          publish=false
          problems+=('Sparkle was not built, so nothing was pushed')
          break
        else
          failed+=("$host")
        fi
      done
      if [ "$publish" = true ] && [ "${#failed[@]}" -gt 0 ]; then
        problems+=("Not built or cached: ${failed[*]}")
      fi
    fi
    if [ "$publish" = true ] && ! jq -e -n --slurpfile old <(git show HEAD:flake.lock) --slurpfile new flake.lock \
      -f modules/nixos/nix/ci-lock-check.jq > /dev/null; then
      problems+=('The servers will refuse the pushed commit until a trusted commit follows it; see docs/updates.md')
    fi
  fi

  {
    echo "publish=$publish"
    output_list files "${files[@]}"
    output_list paths "${paths[@]}"
    output_list problems "${problems[@]}"
  } >> "$GITHUB_OUTPUT"
}

case "${1:-}" in
  check-cache) check_cache ;;
  format) format ;;
  check) check ;;
  check-pins)
    load_pins
    check_pins
    ;;
  build-uncached) build_uncached ;;
  update) update ;;
  --attempt) "$2" ;;
  *)
    echo "usage: $0 check-cache|format|check|check-pins|build-uncached|update" >&2
    exit 2
    ;;
esac
