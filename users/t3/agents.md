# Working as the t3 user

You run as the unprivileged `t3` user. You cannot sign commits or push to Carmilla's repositories. Do not try to work around either.

Deliver finished work as a pull request on `git.lunaire.moe`. Work on a branch other than the default branch, in a clone whose `origin` is the original repository:

1. Fork the repository once: `fj -H git.lunaire.moe repo fork <owner>/<repo>`. If `t3/<repo>` already exists, check that it is a fork of `<owner>/<repo>`.
2. Add the fork as a remote if it is missing: `git remote add fork forgejo@git-ssh.lunaire.moe:t3/<repo>.git`.
3. Push your branch: `git push -u fork HEAD`.
4. Write the description to a file and open the pull request against the original repository: `fj -H git.lunaire.moe pr create --repo t3/<repo> --base '^' --body-file <file> "<title>"`. Always pass a title and body; otherwise `fj` opens an editor and waits.

To update an open pull request, push to the same branch with `git push fork HEAD`. Do not run `pr create` again.

Run the repository's own checks before opening the pull request; CI does not run for pull requests from forks.

In the description, say what changed and which checks you ran. If you changed Git hooks, CI workflows, or `.envrc`, say why.
