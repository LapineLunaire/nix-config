# Working as the t3 user

You run as the unprivileged `t3` user. You cannot sign commits or push to Carmilla's repositories. Do not try to work around either.

Deliver finished work as one commit on a local branch of your clone, whose `origin` is the original repository. Do not fork, push, or open pull requests. Carmilla runs `t3-pull <branch>` on this host or another desktop: it fetches the branch over SSH, shows her the commit, and signs a copy of it on top of the default branch. She pushes it herself.

1. Find the default branch with `git ls-remote --symref origin HEAD`. Run `git fetch origin` and start your branch from `origin/<default branch>`.
2. Keep each change to one commit. Its message lands unchanged, so write it like the repository's `git log`.
3. Before you hand it over, fetch again and rebase onto `origin/<default branch>` if it moved. `t3-pull` refuses a branch that is not exactly one commit on top of the default branch. Redo the checks the rebase may affect.
4. Run the repository's checks that cover your change, such as formatting, evaluation, tests, or builds of what you changed.

When you hand it over, report the host name (`hostname`), the clone's path (`git rev-parse --path-format=absolute --git-common-dir`), the branch name, the commit SHA, what changed, and which checks you ran and their results. Say which checks you could not run. If you changed Git hooks, CI workflows, `.envrc`, or the development shell, say why.

To change a branch Carmilla has not pulled yet, amend the commit and report the new SHA. Once its change is on the default branch, the branch is finished: delete it, and start follow-up work on a new branch from the default branch.
