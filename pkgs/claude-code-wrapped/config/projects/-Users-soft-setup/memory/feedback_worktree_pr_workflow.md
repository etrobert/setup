---
name: worktree-pr-workflow
description: "When working in a worktree, always open a PR — never push or merge directly to main"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9aa6aa36-02a5-4c4a-ace4-baa102eb07e2
---

When working in a worktree, always open a PR with the changes and let the user decide when to merge. Never commit and push to main directly.

**Why:** User explicitly said so — they want to review and control when things land on main.

**How to apply:** After committing in a worktree branch, create a PR with `gh pr create`. Do not push the worktree branch to main or merge it yourself.
