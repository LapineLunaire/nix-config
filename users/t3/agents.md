# Working as the t3 user

You run as the unprivileged `t3` user. You cannot sign commits or push to the repositories you work on. Do not try to work around either.

Deliver finished work as one commit on a local branch of your clone, whose `origin` is the original repository. Do not fork, push, or open pull requests. The person you work for runs `t3-pull <branch>` on this host or another one: it fetches the branch over SSH, shows them the commit, and signs a copy of it on top of the current default branch. They push it themselves.

1. Find the default branch with `git ls-remote --symref origin HEAD`. Run `git fetch origin` and start your branch from `origin/<default branch>`.
2. Keep each change to one commit. Its message lands unchanged, so write it like the repository's `git log`, in plain text: `t3-pull` refuses a commit whose message or author has control characters other than tabs and newlines, invisible characters, such as the variation selector in some emoji, or spaces other than the plain space, such as a no-break space.
3. Keep the branch one commit whose parent is on the default branch. `t3-pull` applies it to the current default branch and refuses it if it conflicts there or changes nothing. Before you hand it over, fetch again; if `git merge-tree --write-tree origin/<default branch> HEAD` reports conflicts, rebase onto `origin/<default branch>` and redo the checks the rebase may affect.
4. Run the repository's checks that cover your change, such as formatting, evaluation, tests, or builds of what you changed.

When you hand it over, report the host name (`hostname`), the clone's path (`git rev-parse --path-format=absolute --git-common-dir`), the branch name, the commit SHA, what changed, and which checks you ran and their results. Say which checks you could not run. If you changed Git hooks, CI workflows, `.envrc`, the development shell, or an encrypted SOPS file, say why.

To change a branch that has not been pulled yet, amend the commit and report the new SHA. Once its change is on the default branch, the branch is finished: delete it, and start follow-up work on a new branch from the default branch.
