# Working as the t3 user

You run as the unprivileged `t3` user. You cannot sign commits or push to Carmilla's repositories. Do not try to work around either.

Deliver finished work as a pull request on `git.lunaire.moe`. Work on a branch other than the default branch, in a clone whose `origin` is the original repository:

1. Fork the repository once: `fj -H git.lunaire.moe repo fork <owner>/<repo>`. If `t3/<repo>` already exists, check that it is a fork of `<owner>/<repo>`.
   Then give Carmilla write access to the fork, because she lands pull requests by pushing to their branches. `fj` has no command for it, so call the API with its token. Keep the token out of command arguments:
   ```sh
   token=$(sed -n 's/.*"token": *"\([^"]*\)".*/\1/p' ~/.local/share/forgejo-cli/keys.json)
   printf 'Authorization: token %s\n' "$token" | curl --fail --silent --show-error --header @- -X PUT --json '{"permission":"write"}' https://git.lunaire.moe/api/v1/repos/t3/<repo>/collaborators/carmilla
   ```
2. Add the fork as a remote if it is missing: `git remote add fork forgejo@git-ssh.lunaire.moe:t3/<repo>.git`.
3. Find the default branch with `git ls-remote --symref origin HEAD`. Run `git fetch origin` and start your branch from `origin/<default branch>`. Before the first push, fetch again and rebase onto it if it moved.
   Whenever you push, first run `git fetch origin`, then update the fork's default branch: `git push fork origin/<default branch>:refs/heads/<default branch>`. If `git ls-remote --symref fork HEAD` names a different default branch, or that push is rejected, say so instead of changing the fork's branches yourself.
4. Push your branch: `git push -u fork HEAD`.
5. Write the description to a file and open the pull request against the original repository: `fj -H git.lunaire.moe pr create --repo t3/<repo> --base '^' --body-file <file> "<title>"`. Always pass a title and body; otherwise `fj` opens an editor and waits.

To update an open pull request, push to the same branch with `git push fork HEAD`. Do not run `pr create` again.

Carmilla lands a pull request as one commit with her as author and the pull request's title as its subject, so write the title like a commit subject in the repository's style, and keep each pull request to one change. She pushes that commit to your branch on the fork and then to the default branch. After that, the branch is finished: do not push to it again, and start follow-up work on a new branch from the default branch.

Use CI for the full repository checks after Carmilla reviews the changes and approves the workflow run. Run targeted local checks when needed to develop or debug a change; do not repeat the full CI suite before opening the pull request. Report pending CI as pending, not passed.

In the description, say what changed and which checks you ran. If you changed Git hooks, CI workflows, or `.envrc`, say why.
