# CLAUDE.md

## Running Packages

If a needed tool is not installed on the system, use `nix run nixpkgs#<package>`
or the comma shorthand `, <package>` rather than skipping the step.

## Code Style

Always format, typecheck, and lint after making a change.

## Git Workflow

Run `git alias` to discover available git aliases before running git commands.

After committing on a branch, open a PR with `gh pr create`. Never merge to
main directly — the user reviews all code and decides when to merge.
