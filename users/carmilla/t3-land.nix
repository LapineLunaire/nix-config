{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "t3-land";
      runtimeInputs = [pkgs.git];
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
        # The pull request's files must not run as Carmilla: no hooks such as .githooks/pre-merge-commit, no fsmonitor, no pager.
        g() {
          git --no-pager -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
        }

        cd "$(git rev-parse --show-toplevel)"
        hooks=$(git config core.hooksPath || true)
        # Filters and merge drivers run on the pull request's files. A repository's own config can also
        # include files from the work tree or name programs there, which the merge would replace.
        unsafe=$(
          git config --get-regexp '^(filter\..*\.(clean|smudge|process)|merge\..*\.driver)$' || true
          git config --local --get-regexp '^(include\.|includeif\.|core\.sshcommand$|gpg\.|credential\.)' || true
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
        g merge-base --is-ancestor "$remote/$branch" HEAD || die "$branch is behind $remote/$branch; pull first"
        ! g merge-base --is-ancestor "$head" HEAD || die "pull request $number is already in $branch"

        g log --reverse --stat --no-textconv --format='%n%C(yellow)%h%Creset %s%n%an <%ae>' "HEAD..$head"
        # These run later as Carmilla: hooks on her next commit, workflows on the runner, .envrc when she enters the directory.
        risky=$(g diff --name-only "HEAD...$head" -- ''${hooks:+"$hooks"} .forgejo .envrc)
        if [ -n "$risky" ]; then
          printf '\nThis pull request changes files that run code later:\n%s\n' "$risky"
        fi
        echo
        read -r -p "Merge these commits ($head) into $branch, sign the merge, and push to $remote? [y/N] " answer
        [ "$answer" = y ] || die "nothing merged"

        if ! g merge --no-ff --no-edit -S -m "Merge pull request #$number" "$head"; then
          g merge --abort 2> /dev/null || true
          die "the merge or its signature failed; nothing changed"
        fi
        g push "$remote" "HEAD:refs/heads/$branch"
      '';
    })
  ];
}
