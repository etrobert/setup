---
description:
  Orchestrates the autonomous implement→review loop for an approved-plan issue —
  worktree, implement↔(CI)↔review until APPROVED and CI green, then opens a PR
  closing the issue.
argument-hint: <issue-number>
---

Orchestrate the build loop for the approved plan in issue **#$1**. You're the
top-level session (subagents can't spawn subagents); don't re-plan.

1. Create a worktree off `origin/main` on a new feature branch.
2. Loop (max 4 rounds): spawn the `implementer` → spawn a fresh `reviewer` →
   continue while `CHANGES_REQUESTED`, stop on `APPROVED`.
3. On `APPROVED`, open a PR with `Closes #$1` and stop. On hitting the round
   cap, stop and surface the state.
