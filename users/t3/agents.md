# Working as the t3 user

You run as the unprivileged `t3` user. You cannot sign commits or push to the repositories you work on. Do not try to work around either.

Deliver finished work as one commit on a local branch of your clone, whose `origin` is the original repository. Do not fork, push, or open pull requests. The person you work for runs `t3-pull <branch>` on this host or another one: it fetches the branch over SSH, shows them the commit, and signs a copy of it, with them as the author, on top of the current default branch. They push it themselves.

1. Find the default branch with `git ls-remote --symref origin HEAD`. Run `git fetch origin` and start your branch from `origin/<default branch>`.
2. Keep each change to one commit. Its message lands unchanged, so write it like the repository's `git log`, in plain text: `t3-pull` refuses a commit whose message or author has control characters other than tabs and newlines, invisible characters, such as the variation selector in some emoji, or spaces other than the plain space, such as a no-break space.
3. Keep the branch one commit whose parent is on the default branch. `t3-pull` applies it to the current default branch and refuses it if it conflicts there or changes nothing. Before you hand it over, fetch again; if `git merge-tree --write-tree origin/<default branch> HEAD` reports conflicts, rebase onto `origin/<default branch>` and redo the checks the rebase may affect.
4. Run the repository's checks that cover your change, such as formatting, evaluation, tests, or builds of what you changed.

When you hand it over, report the host name (`hostname`), the clone's path (`git rev-parse --path-format=absolute --git-common-dir`), the branch name, the commit SHA, what changed, and which checks you ran and their results. Say which checks you could not run. If you changed Git hooks, CI workflows, `.envrc`, the development shell, or an encrypted SOPS file, say why.

To change a branch that has not been pulled yet, amend the commit and report the new SHA. Once its change is on the default branch, the branch is finished: delete it, and start follow-up work on a new branch from the default branch.

## Follow-up work on a pull request's branch

When the person asks for a change to an open pull request, or tells you to use its branch, the commit goes onto that branch instead of the default branch. They land it with `t3-pull --onto <their branch> <your branch>`, which works the same way, with the pull request's branch in place of the default branch. Steps 2 and 4 apply as they are. The rest changes like this:

1. Fetch the pull request's branch from the repository it lives in, which can be a fork: add that as a remote, or run `git fetch <URL> <branch>`. Ask if you cannot tell which it is. Start your branch from the fetched head.
2. Keep your branch one commit whose parent is on the pull request's branch, not on the default branch. `t3-pull` refuses it if its parent is not in that branch's history, or if it conflicts with the branch's current head or changes nothing there. Before you hand it over, fetch the pull request's branch again; if it moved and `git merge-tree --write-tree <its head> HEAD` reports conflicts, rebase onto its head and redo the checks the rebase may affect.

In the report, add the pull request, the name of its branch, the SHA of the head your commit sits on, and the command to run. The person runs it in their checkout with the pull request's branch checked out and pushed, and `--onto` takes that branch's name in their checkout, which can differ from yours:

```sh
t3-pull --onto <pull request branch> [--host <host of your clone>] <your branch> <path of your clone>
```

Do not suggest another way to get the commit, such as `git fetch <host>:<path>`. Only `t3` can read `/var/lib/t3`, so the person's own login cannot read your clone. `t3-pull` logs in as `t3` over SSH, to `127.0.0.1` or to the host given with `--host`, and it is what checks and signs the commit.

Once the commit is pulled, the pull request's branch holds a signed copy of it with another SHA. Delete your branch, and start more follow-up work from the pull request's new head.
