# CLAUDE.md

## About the User

Étienne Robert — software engineer with 15 years of experience, and a queer
creative (dance, sewing, makeup, aerials, and more). Uses Claude for both
software engineering and non-technical work. Tracks life documentation in
Markdown files, often located at `~/sync/doc`.

## Running Packages

If a needed tool is not installed on the system, use `nix run nixpkgs#<package>`
or the comma shorthand `, <package>` rather than skipping the step.

## Code Style

Always format, typecheck, and lint after making a change.

## Testing

Always test that code works before committing. Run the relevant test, build, or
manual verification step first.

## Git Workflow

Run `git alias` to discover available git aliases before running git commands.

After committing on a branch, open a PR with `gh pr create`. Never merge to
main directly — the user reviews all code and decides when to merge.
