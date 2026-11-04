{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "t3-land";
      runtimeInputs = [pkgs.git pkgs.coreutils pkgs.gawk pkgs.gnused pkgs.curl pkgs.jq pkgs.iconv];
      text = ''
        # Squashes a Forgejo pull request's head commit into one signed commit on the default branch. The commit goes to the
        # pull request's branch first, so Forgejo finds the pull request's head on the default branch and marks it as merged.
        usage() {
          echo "usage: t3-land [--prepare] <pull request number> [remote]" >&2
          exit 2
        }
        prepare_only=
        if [ "''${1-}" = --prepare ]; then
          prepare_only=1
          shift
        fi
        if [ $# -lt 1 ] || [ $# -gt 2 ] || ! [[ $1 =~ ^[0-9]+$ ]]; then
          usage
        fi
        number=$1
        remote=''${2:-origin}
        die() {
          echo "t3-land: $*" >&2
          exit 1
        }
        # Git variables such as GIT_SSH_COMMAND or GIT_CONFIG_PARAMETERS could run the pull request's files as Carmilla.
        # This bash has no compgen, so the names come from parameter expansion.
        for name in "''${!GIT_@}"; do
          unset "$name"
        done
        cd "$(git rev-parse --show-toplevel)"

        # The system and global config are skipped too, because their helpers and filters could name files in the work tree.
        # Only the identity and signing settings are kept.
        keep=()
        for key in user.name user.email user.signingkey gpg.format; do
          if value=$(git config "$key"); then
            keep+=(-c "$key=$value")
          fi
        done
        g() {
          GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
            git --no-pager -c core.hooksPath=/dev/null -c core.fsmonitor=false -c i18n.commitEncoding=UTF-8 "''${keep[@]}" "$@"
        }

        # Hooks run on Carmilla's next commit. Only hooks inside the work tree can come from the pull request.
        # The path as written and its symlink target are both checked, because the pull request can replace either.
        hooks=()
        if configured=$(git config --type=path core.hooksPath); then
          for path in "$(realpath -m -s --relative-to=. -- "$configured")" "$(realpath -m --relative-to=. -- "$configured")"; do
            case "$path" in .. | ../*) ;; *) hooks+=("$path") ;; esac
          done
        fi
        # The repository's own and worktree config could run the pull request's files: filters and merge and diff drivers run on them,
        # and hooks, includes, or programs can name files in the work tree. core.hooksPath does not turn off hooks set in config.
        unsafe=$(
          GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git config --get-regexp \
            '^(filter\..*\.(clean|smudge|process)|merge\..*\.driver|diff\..*\.(command|textconv)|diff\.external|include\.|includeif\.|hook\.|core\.(sshcommand|askpass|gitproxy)|protocol\.|gpg\.|credential\.)' || true
        )
        [ -z "$unsafe" ] || die "this repository's Git config could run the pull request's files during the merge or push:
        $unsafe"
        branch=$(g ls-remote --symref "$remote" HEAD | sed -n 's|^ref: refs/heads/\(.*\)\tHEAD$|\1|p')
        [ -n "$branch" ] || die "cannot find the default branch of $remote"
        [ "$(g symbolic-ref --quiet --short HEAD)" = "$branch" ] || die "switch to $branch first"
        if ! g diff --quiet || ! g diff --cached --quiet; then
          die "commit or stash your changes first"
        fi
        url=$(g remote get-url "$remote")
        case "$url" in
          forgejo@git-ssh.lunaire.moe:*) repo=''${url#forgejo@git-ssh.lunaire.moe:} ;;
          ssh://forgejo@git-ssh.lunaire.moe/*) repo=''${url#ssh://forgejo@git-ssh.lunaire.moe/} ;;
          https://git.lunaire.moe/*) repo=''${url#https://git.lunaire.moe/} ;;
          *) die "cannot find the Forgejo API for $url" ;;
        esac
        repo=''${repo%.git}
        api=https://git.lunaire.moe/api/v1/repos/$repo/pulls/$number
        pull=https://git.lunaire.moe/$repo/pulls/$number
        # The CI state of a commit, such as success, pending, or failure; a cancelled run counts as failure. The validation job
        # must have passed, because any other workflow the pull request adds could pass without checking anything, and every
        # other run must have passed too.
        ci_state() {
          curl --fail --silent --show-error "https://git.lunaire.moe/api/v1/repos/$repo/commits/$1/status" |
            jq -r '([.statuses[]? | select(.context == "Validate / validate (pull_request)") | .status] | first) as $validation
              | if $validation == null then "missing the Validate run" elif $validation != "success" then $validation else .state end' ||
            echo unknown
        }

        ref=refs/t3-land/$number
        # Kept after either mode pushes to the fork, so running again lands the same commit once CI passes.
        prepared=refs/t3-land/prepared/$number
        trap 'g update-ref -d "$ref" 2> /dev/null || true' EXIT
        g fetch --no-tags "$remote" "+refs/heads/$branch:refs/remotes/$remote/$branch" "+refs/pull/$number/head:$ref"
        head=$(g rev-parse --verify "$ref^{commit}")
        # Otherwise local commits would be pushed with the pull request without being shown.
        # Later steps use this commit instead of HEAD, so a commit made elsewhere during the prompt is not undone.
        base=$(g rev-parse "$remote/$branch")
        [ "$(g rev-parse HEAD)" = "$base" ] || die "$branch does not match $remote/$branch; pull or push first"
        ! g merge-base --is-ancestor "$head" "$base" || die "pull request $number is already in $branch"

        info=$(curl --fail --silent --show-error "$api") || die "cannot read pull request $number from Forgejo; nothing changed"
        jq -e '.state == "open"' <<< "$info" > /dev/null || die "pull request $number is not open"
        jq -e --arg branch "$branch" '.base.ref == $branch' <<< "$info" > /dev/null || die "pull request $number does not target $branch"
        [ "$(jq -r '.head.sha' <<< "$info")" = "$head" ] || die "pull request $number changed while it was fetched; run t3-land again"
        title=$(jq -r '.title // ""' <<< "$info")
        if [[ $title =~ [[:cntrl:]] || ! $title =~ [^[:space:]] ]]; then
          die "pull request $number needs a one-line title; it becomes the commit subject"
        fi
        # Other URLs, such as <transport>::<address>, can make Git run a helper program, so only the Forgejo SSH address is accepted.
        fork=$(jq -r '.head.repo.ssh_url // ""' <<< "$info")
        [[ $fork =~ ^ssh://forgejo@git-ssh\.lunaire\.moe/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$ ]] ||
          die "cannot find the repository of pull request $number's branch"
        source=$(jq -r '.head.ref // ""' <<< "$info")
        if [[ $source == -* || $source == refs/* ]] || ! g check-ref-format "refs/heads/$source"; then
          die "cannot find the branch of pull request $number"
        fi

        if commit=$(g rev-parse --verify --quiet "$prepared^{commit}"); then
          # The title is checked too, because it becomes the commit message and can be edited after the commit was prepared.
          if [ "$commit" = "$head" ] && [ "$(g rev-parse "$commit^")" = "$base" ] && [ "$(g log -1 --format=%B "$commit")" = "$title" ]; then
            [ -z "$prepare_only" ] || die "pull request $number is already prepared as $commit; run t3-land $number to land it"
            state=$(ci_state "$commit")
            [ "$state" = success ] || die "CI on the prepared commit $commit is $state, not success. Check its run at $pull; nothing changed."
            g show --stat --no-textconv --format='%n%h %s%n%an <%ae>' "$commit"
            read -r -p "Push the prepared commit $commit to $remote/$branch? [y/N] " answer
            [ "$answer" = y ] || die "nothing changed"
          else
            # A new commit has not passed CI, so it stops for CI again.
            echo "The commit prepared for pull request $number is out of date, so it is made again for CI."
            g update-ref -d "$prepared"
            commit=
            prepare_only=1
          fi
        fi

        if [ -z "$commit" ]; then
          # If the pull request contains the default branch, the squashed commit has the head's tree, so CI on the head
          # checked what lands. Otherwise --prepare runs CI on the squashed commit.
          if [ -z "$prepare_only" ]; then
            g merge-base --is-ancestor "$base" "$head" ||
              die "pull request $number does not contain the latest $branch, so its CI did not check what would land. Run t3-land --prepare $number; nothing changed."
            state=$(ci_state "$head")
            [ "$state" = success ] ||
              die "CI on pull request $number's head $head is $state, not success. Approve and wait for its run at $pull, or run t3-land --prepare $number; nothing changed."
          fi
          tree=$(g merge-tree --write-tree "$base" "$head") || die "pull request $number conflicts with $branch; nothing changed"
          [ "$tree" != "$(g rev-parse "$base^{tree}")" ] || die "$branch already has every change in pull request $number; nothing changed"
          # Commit messages and authors come from the pull request, so control characters are removed before they reach the terminal.
          # sed does not match bytes that are not valid UTF-8, so those are refused first.
          log=$(g log --reverse --no-textconv --format='%h %s  %an <%ae>' "$base..$head")
          iconv -f UTF-8 -t UTF-8 <<< "$log" > /dev/null 2>&1 || die "pull request $number has commit messages or authors that are not valid UTF-8"
          printf '%s\n' "$log" | LC_ALL=C.UTF-8 sed 's/[[:cntrl:]]//g'
          echo
          # The diff is of the tree that lands, which can differ from the pull request's own diff, for example when the merge follows a rename.
          g diff --stat --no-textconv "$base" "$tree"
          # These act later: hooks on Carmilla's next commit, workflows on the runner, .envrc with the flake's development shell
          # when she enters the directory, project settings and instructions of her coding agents and editor, and .sops.yaml when she
          # encrypts secrets. The development shell sets core.hooksPath to .githooks. Symlinks are listed because they can redirect
          # any of these paths or their parents.
          risky=$(
            {
              g diff --name-only "$base" "$tree" -- "''${hooks[@]}" .githooks .forgejo .envrc flake.nix flake.lock .sops.yaml .claude .codex .mcp.json .zed "*AGENTS.md" "*CLAUDE.md"
              g diff --raw --no-renames "$base" "$tree" | awk -F '\t' '$1 ~ /(^:| )120000 / { print $2 }'
            } | sort -u
          )
          if [ -n "$risky" ]; then
            printf '\nThis pull request changes files that act later:\n%s\n' "$risky"
          fi
          next="push it to $remote/$branch"
          [ -z "$prepare_only" ] || next="stop for CI"
          printf '\n%s\n' "$title"
          read -r -p "Squash pull request $number ($head) into this commit as $(g config user.name), sign it, push it to $source on $fork, and $next? [y/N] " answer
          [ "$answer" = y ] || die "nothing changed"

          # The work tree is not touched until after the push, so SSH or signing helpers that name files there run
          # Carmilla's current files, not the pull request's.
          commit=$(g commit-tree -S -p "$base" -m "$title" "$tree") || die "signing failed; nothing changed"
          # The lease fails if the branch moved since the fetch, so later commits are never dropped.
          g push --force-with-lease="refs/heads/$source:$head" "$fork" "$commit:refs/heads/$source" ||
            die "could not replace $source on $fork; if the pull request changed, review it again. Nothing was pushed to $branch."
          g update-ref "$prepared" "$commit"
          if [ -n "$prepare_only" ]; then
            echo "Pushed $commit to $source. Once its CI run at $pull passes, run t3-land $number again."
            exit 0
          fi
        fi

        # Forgejo updates the pull request's head in the background; it must hold the commit before the default branch does,
        # or the merge may not be detected. It is checked over HTTPS, because each SSH connection can ask for a YubiKey touch.
        synced=
        for _ in $(seq 30); do
          if [ "$(g ls-remote "https://git.lunaire.moe/$repo.git" "refs/pull/$number/head" | cut -f1)" = "$commit" ]; then
            synced=1
            break
          fi
          sleep 1
        done
        [ -n "$synced" ] || die "Forgejo has not updated pull request $number to $commit yet, so nothing was pushed to $branch. Once its CI run at $pull passes, run t3-land $number again."
        # The commit's parent is the fetched tip; a normal push rejects a default branch that diverged.
        g push "$remote" "$commit:refs/heads/$branch" ||
          die "the push to $branch failed. $source on $fork now holds $commit; pull, then run t3-land $number again to make it on top of the new $branch and stop for CI."
        g update-ref -d "$prepared"

        merged=
        for _ in $(seq 15); do
          if info=$(curl --fail --silent "$api") && jq -e '.merged == true' <<< "$info" > /dev/null; then
            merged=1
            break
          fi
          sleep 1
        done
        # The checkout catches up either way, because the default branch already holds the commit.
        g merge --ff-only --quiet "$commit" || die "pushed $commit, but $branch could not fast-forward to it; run git pull"
        if [ -z "$merged" ]; then
          if [ -n "$info" ] && [ "$(jq -r '.head.sha' <<< "$info")" != "$commit" ]; then
            die "pushed $commit, but $pull now has commits pushed after it; review them, or close the pull request if they are not wanted."
          fi
          die "pushed $commit, but Forgejo has not marked $pull as merged. Check that the repository has \"Autodetect manual merge\" on; otherwise mark it as manually merged at $commit."
        fi
        echo "Pushed $commit. Forgejo marked $pull as merged."
      '';
    })
  ];
}
