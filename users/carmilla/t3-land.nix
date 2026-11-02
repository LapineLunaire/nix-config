{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "t3-land";
      runtimeInputs = [pkgs.git pkgs.coreutils pkgs.gawk pkgs.gnused pkgs.curl pkgs.jq];
      text = ''
        # Merges a Forgejo pull request's exact head commit with one signed merge commit, then pushes it.
        if [ $# -lt 1 ] || [ $# -gt 2 ] || ! [[ $1 =~ ^[0-9]+$ ]]; then
          echo "usage: t3-land <pull request number> [remote]" >&2
          exit 2
        fi
        number=$1
        remote=''${2:-origin}
        die() {
          echo "t3-land: $*" >&2
          exit 1
        }
        # The pull request's files must not run as Carmilla. Git variables such as GIT_SSH_COMMAND or
        # GIT_CONFIG_PARAMETERS could name them, so none are inherited.
        while IFS= read -r name; do
          [[ $name != GIT_* ]] || unset "$name"
        done < <(compgen -e)
        cd "$(git rev-parse --show-toplevel)"

        # Git also skips the system and global config, so their helpers and filters cannot name files in the
        # work tree; only the identity and signing key are kept. Hooks, fsmonitor, and the pager are off.
        keep=()
        for key in user.name user.email user.signingkey gpg.format; do
          if value=$(git config "$key"); then
            keep+=(-c "$key=$value")
          fi
        done
        g() {
          GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
            git --no-pager -c core.hooksPath=/dev/null -c core.fsmonitor=false "''${keep[@]}" "$@"
        }

        # Hooks run on Carmilla's next commit. Only hooks inside the work tree can come from the pull request.
        # Both the path as written and its symlink target are checked, because the pull request can replace either.
        hooks=()
        if configured=$(git config --type=path core.hooksPath); then
          for path in "$(realpath -m -s --relative-to=. -- "$configured")" "$(realpath -m --relative-to=. -- "$configured")"; do
            case "$path" in .. | ../*) ;; *) hooks+=("$path") ;; esac
          done
        fi
        # The repository's config, including worktree config, could run the pull request's files: filters, merge
        # and diff drivers run on them, and includes or programs can name files in the work tree.
        unsafe=$(
          GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git config --get-regexp \
            '^(filter\..*\.(clean|smudge|process)|merge\..*\.driver|diff\..*\.(command|textconv)|diff\.external|include\.|includeif\.|core\.(sshcommand|askpass|gitproxy)|protocol\.|gpg\.|credential\.)' || true
        )
        [ -z "$unsafe" ] || die "this repository's Git config could run the pull request's files during the merge or push:
        $unsafe"
        branch=$(g ls-remote --symref "$remote" HEAD | sed -n 's|^ref: refs/heads/\(.*\)\tHEAD$|\1|p')
        [ -n "$branch" ] || die "cannot find the default branch of $remote"
        [ "$(g symbolic-ref --quiet --short HEAD)" = "$branch" ] || die "switch to $branch first"
        if ! g diff --quiet || ! g diff --cached --quiet; then
          die "commit or stash your changes first"
        fi

        ref=refs/t3-land/$number
        trap 'g update-ref -d "$ref" 2> /dev/null || true' EXIT
        g fetch --no-tags "$remote" "+refs/heads/$branch:refs/remotes/$remote/$branch" "+refs/pull/$number/head:$ref"
        head=$(g rev-parse --verify "$ref^{commit}")
        # Otherwise local commits would be pushed with the merge without being shown.
        [ "$(g rev-parse HEAD)" = "$(g rev-parse "$remote/$branch")" ] || die "$branch does not match $remote/$branch; pull or push first"
        ! g merge-base --is-ancestor "$head" HEAD || die "pull request $number is already in $branch"

        g log --reverse --stat --no-textconv --format='%n%C(yellow)%h%Creset %s%n%an <%ae>' "HEAD..$head"
        # These run later as Carmilla: hooks on her next commit, workflows on the runner, and .envrc with the flake's development shell when she enters the directory.
        # Symlinks are listed too, because they can redirect any of these paths, including the hooks directory or its parents.
        risky=$(
          {
            g diff --name-only "HEAD...$head" -- "''${hooks[@]}" .forgejo .envrc flake.nix flake.lock
            g diff --raw --no-renames "HEAD...$head" | awk -F '\t' '$1 ~ /(^:| )120000 / { print $2 }'
          } | sort -u
        )
        if [ -n "$risky" ]; then
          printf '\nThis pull request changes files that run code later:\n%s\n' "$risky"
        fi
        echo
        url=$(g remote get-url "$remote")
        case "$url" in
          forgejo@git-ssh.lunaire.moe:*) repo=''${url#forgejo@git-ssh.lunaire.moe:} ;;
          ssh://forgejo@git-ssh.lunaire.moe/*) repo=''${url#ssh://forgejo@git-ssh.lunaire.moe/} ;;
          https://git.lunaire.moe/*) repo=''${url#https://git.lunaire.moe/} ;;
          *) die "cannot find the Forgejo API for $url" ;;
        esac
        repo=''${repo%.git}
        title=$(curl --fail --silent --show-error "https://git.lunaire.moe/api/v1/repos/$repo/pulls/$number" |
          jq -er '.title | select(type == "string" and test("[^[:space:]]"))') || die "cannot read the pull request title; nothing merged"
        message="Merge pull request #$number: $title"
        printf '\n%s\n' "$message"
        read -r -p "Merge these commits ($head) into $branch, sign the merge, and push to $remote? [y/N] " answer
        [ "$answer" = y ] || die "nothing merged"

        # The merge is made, signed, and pushed without touching the work tree, so SSH or signing helpers that
        # name files there run Carmilla's current files, not the pull request's. The checkout catches up afterwards.
        tree=$(g merge-tree --write-tree HEAD "$head") || die "the pull request conflicts with $branch; nothing changed"
        merge=$(g commit-tree -S -p HEAD -p "$head" -m "$message" "$tree") || die "signing failed; nothing changed"
        g push "$remote" "$merge:refs/heads/$branch" || die "the push failed; nothing changed"
        g merge --ff-only --quiet "$merge" || die "pushed $merge, but $branch could not fast-forward to it; run git pull"
      '';
    })
  ];
}
