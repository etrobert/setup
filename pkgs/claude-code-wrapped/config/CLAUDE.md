# CLAUDE.md

## Running Packages

If a needed tool is not installed on the system, use `nix run nixpkgs#<package>`
or the comma shorthand `, <package>` rather than skipping the step. Do not
suggest `brew install` — Nix is the package manager.

## Git Workflow

When working in a worktree branch, always open a PR with `gh pr create` after
committing. Never push directly to main or merge the branch yourself — let the
user decide when to merge.
