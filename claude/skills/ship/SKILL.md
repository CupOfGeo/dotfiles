---
name: ship
description: Close out a ticket branch — review it (correctness + over-engineering), talk the findings through with the user, fix on the branch, record the decisions on the Forgejo issue, then squash-merge into main and push. Use whenever the user says /ship, "ship it", "close out this ticket", "merge this branch", "review the branch before merging", or otherwise signals the work on a ticket branch is done and should land on main.
---

# Ship a ticket branch

Solo-dev flow: no pull requests. Each ticket gets a branch named
`<issue#>-<slug>` (e.g. `18-attachments`); the branch review stands in
for the PR review, and main only changes through this skill, one squash
commit per ticket.

The review is a conversation, not a checklist. Findings often raise
questions only the user can answer, and the user will have questions
back. Expect several rounds; never rush to the merge.

## 1. Preflight

- Refuse to run on `main`, or with a dirty tree (ask the user to commit
  or stash first; don't do it for them).
- Issue number = the leading digits of the branch name. If there are
  none, ask which issue this closes.
- `git fetch origin`. If `origin/main` moved since the branch point,
  rebase onto it and rerun the tests before reviewing, so the review
  sees what will actually land.
- Read the issue (`fj issue view N`, plus its comments) for the
  requirements and the decisions already made — the review checks the
  branch against those.
- If the ticket spans a sibling repo with a same-named branch (e.g.
  big-red + imessage-edge), say so and ship them together: review both,
  merge in dependency order (the one whose contract the other consumes
  first).

## 2. Review loop

Repeat until the user says it's ready ("ship it", "looks good, merge").

**Review.** Run both on `git merge-base origin/main HEAD`..`HEAD`:
- `superpowers:requesting-code-review` — correctness, against the issue's
  requirements.
- `ponytail:ponytail-review` — over-engineering: what to delete or shrink.

Verify every finding against the code before reporting it; reviewers
produce false positives, and a wrong finding wastes a round.

**Present everything before fixing anything**, grouped:
- **Fix** — clear defects. Say the fix you'd make.
- **Your call** — judgment calls and trade-offs. Give a recommendation
  and the reason; these need the user's answer.
- **Keep / out of scope** — findings you'd push back on, or that are
  real but belong to another ticket. One line of reasoning each.

Then stop and wait. The user may answer, ask questions, or overrule.
Discuss as long as needed. If something grows into new work, propose a
new issue for it rather than widening the branch.

**Apply** what was agreed: stage the files you changed by name (check
`git status` for strays like `__pycache__` before committing), commit
to the branch (`Refs #N`), run the repo's pre-commit hooks, push the
branch to `origin` as a backup.

**Re-review only the delta** when the fixes were more than trivial
(`<last reviewed sha>..HEAD`), so each round stays small, and present
any new findings the same way.

**Then report back and ask whether the branch is ready.** "Go ahead"
on a set of fixes approves those fixes, not the branch — the user may
want another look or have more questions. Show what changed this round
and the proposed squash commit message (below), and ask: more changes,
or ship?

## 3. Merge gate

Merge only on an explicit go for the merge itself ("ship it", "go",
"merge"). Approving fixes is not approval to merge.

Squash message: a subject line summarising the whole ticket, a short
body of what changed and why (not the branch's commit-by-commit
history), `Closes #N`, and the session's attribution trailer.

## 4. Record the decisions

Once the user says go, post one comment on the issue
(`fj issue comment N --body-file …`) before merging: findings, what the
user decided and why, what was fixed, what was deferred (with new issue
numbers). The repo rule is that a ticket's reasoning lives on the
ticket; posting after the go means the record is final.

## 5. Merge

```bash
git switch main && git pull --ff-only origin main
git merge --squash <branch>
git commit -F <message file>     # pre-commit runs here; fix and retry if it fails
git push origin main
git branch -D <branch>           # -D: squash leaves the branch "unmerged" to git
git push origin --delete <branch>
```

Push only to `origin`. If the repo has other remotes or publish scripts,
leave them alone unless the user asks.

Finish with the merge sha, the issue state (Forgejo closes it from
`Closes #N`), and anything deferred.
