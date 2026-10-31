---
name: fj
description: >-
  Work with George's self-hosted Forgejo (git.mainbranch.net) through the `fj` CLI (forgejo-cli) and the Forgejo
  API, with the standards for issues and PRs: issues, labels, milestones, pull requests, merges, and Forgejo
  Actions runs and their logs. Use it in any repo whose remote is on git.mainbranch.net, whenever the user wants
  an issue filed or edited, a PR opened, updated, checked or merged, a milestone made, or CI status or CI logs —
  and whenever you would otherwise reach for `gh`, which does not work here.
---

# fj: Forgejo at git.mainbranch.net

`gh` does not work: the repos live on a self-hosted Forgejo, not GitHub. Use `fj` (forgejo-cli, v0.7.0) for
issues and PRs, and the Forgejo API with `curl` for what `fj` can't do (CI logs). All repos are public, so the
API needs no token for reads.

## Basics
- Every call takes the host: `fj -H git.mainbranch.net ...`.
- `fj` picks the repo from the git remote of the current directory; `-C <dir>` (global) runs it as if in `<dir>`.
  To name another repo: `-r owner/repo` on `issue create|search`, `pr create`, `milestone *` and `actions tasks`;
  `owner/repo#N` as the ID on commands that take one (`fj -H git.mainbranch.net pr view george/mc-arena#9`).
- Remote URLs: use the SSH URL Forgejo advertises, `ssh://git@git.mainbranch.net:2222/<owner>/<repo>.git`.
- `fj` has no `repo search`: `fj -H git.mainbranch.net user repos` lists the repos.
- Bodies longer than a line go in a file: `--body-file <absolute path>` (create) or the body as one argument
  (`fj pr edit <PR> body "$(cat file)"`).

## Issues and milestones
- Create: `fj issue create --no-template --milestone "<name>" --body-file <abs path> "<title>"`. A repo with issue
  templates refuses without `--no-template` or `--template <name>` (`fj issue templates` lists them). Milestones
  go by name; quote names with spaces.
- Labels come after: `fj issue edit N labels -a <label> ...`. Moving milestone later: `fj issue edit N milestone "<name>"`.
- Choosing a milestone: read the open ones (`fj milestone search`, then `fj milestone view` for descriptions) and
  pick the one whose goal the issue serves, not the newest. If none clearly fits, ask rather than guess.
- Read: `fj issue view N` (plus its comments), `fj issue search <text>`. Comment: `fj issue comment N --body-file …`.
  Close: `fj issue close N`. Dependencies: `fj issue depend` / `fj issue block`.
- Milestones: `fj milestone create|view|edit|search`. A milestone's description holds its definition of done; pick
  work from the top of a milestone, not at random.
- Bodies start from this skill's templates: copy one to a temp file, fill it in, delete sections that don't apply,
  and file it with `--no-template --body-file`.
  - `templates/bug.md`: something is broken.
  - `templates/spec.md`: architectural work (new subsystem, cross-repo or interface change). The issue is the spec;
    no spec file in the repo.
  - Anything else: no template, but when the value isn't obvious from the title, open with a one-line user story
    (As X, I want Y, so that Z) so the motivation survives if the details go stale.
- Decisions made in a session go on the issue as a comment, so the reasoning outlives the session.
- References: `#N` means the current repo. A commit or PR in another repo must write `owner/repo#N`. A cross-repo
  `Closes owner/repo#N` doesn't always close the issue: check with `fj issue view`, and `fj issue close` if needed.

## Pull requests
- Open: `fj pr create --base main --head <branch> --body-file <abs path> "<title>"` (`--milestone "<name>"` works
  here too). Push the branch first.
- Check: `fj pr view <PR>`, `fj pr status <PR>` (mergeable? CI?).
- Update after pushing more: `fj pr edit <PR> body "…"`, `fj pr edit <PR> title "…"`.
- Merge only on an explicit go for the merge itself; approving fixes or opening the PR is not one. Editing or
  commenting on a PR needs the user's OK too. Squash merge: `fj pr merge <PR> -M squash -d -t "<subject>" -m "<body>"`.
- After a squash merge the branch's commits are not in main: `git branch -d` refuses, use `-D` once
  `git diff <branch> origin/main` is empty. A commit ID recorded on the branch (e.g. in `.git-blame-ignore-revs`)
  must be replaced with the squash commit's.

## CI runs and logs
`fj actions tasks` lists runs (`#N (sha) status job duration (event): title`); `fj actions dispatch` starts a
workflow; `fj actions variables|secrets` manage those. `fj` cannot show logs (open upstream issues
[#216](https://codeberg.org/forgejo-contrib/forgejo-cli/issues/216) and
[#669](https://codeberg.org/forgejo-contrib/forgejo-cli/issues/669); drop this section once one lands). The
Forgejo API can, with no token.

One run has three numbers, and only the last one gets you a log:
- `#N` in `fj actions tasks` and in the web URL `/actions/runs/N` is the run's `index_in_repo`.
- The API's run `id` is a different, instance-wide number.
- Logs are per job, by the job's `id` (not its `task_id`, which 404s).

```bash
B=https://git.mainbranch.net/api/v1/repos/<owner>/<repo>/actions
curl -s "$B/runs" | jq '.workflow_runs[] | {index_in_repo, id, status, prettyref, commit_sha, title}'
RUN=$(curl -s "$B/runs" | jq '.workflow_runs[] | select(.index_in_repo == N) | .id')   # #N -> run id
curl -s "$B/runs/$RUN/jobs" | jq '.[] | {id, name, status}'
curl -s "$B/jobs/<job id>/logs"                     # one job's plain-text log
curl -s -o run.zip "$B/runs/$RUN/logs"              # every job's log, zipped
```

`/runs` returns the newest runs first; add `?limit=50` if `#N` is older.

Read the log before calling a green run good: warnings (e.g. an unsupported Node engine) don't fail a job.
