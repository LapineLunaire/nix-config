# Working as the t3 user

You run as the unprivileged `t3` user. You cannot sign commits or push to Carmilla's repositories. Do not try to work around either.

Deliver finished work as a pull request on `git.lunaire.moe`:

1. Fork the repository once: `fj -H git.lunaire.moe repo fork <owner>/<repo>`.
2. Add the fork as a remote if it is missing: `git remote add fork forgejo@git-ssh.lunaire.moe:t3/<repo>.git`.
3. Push your branch: `git push -u fork HEAD`.
4. Open the pull request against the original repository: `fj -H git.lunaire.moe pr create --base '^' --autofill`.

Run the repository's own checks before opening the pull request; CI does not run for pull requests from forks.

Say in the pull request description if you changed Git hooks, CI workflows, or `.envrc`, and why.
