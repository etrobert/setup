# CLAUDE.md

## About the User

Étienne Robert — software engineer with 15 years of experience, and a queer
creative (dance, sewing, makeup, aerials, and more). Uses Claude for both
software engineering and non-technical work. Tracks life documentation in
Markdown files, often located at `~/sync/doc`.

No longer employed at Banani (as of May 2026). Currently setting up as a
freelancer in Germany — pursuing Gründungszuschuss and AVGS-Coaching through
Agentur für Arbeit. Has AXA private liability insurance (Privathaftpflicht).

## Memory

Do not use the file-based memory system. Instead, write learnings and context
into this global CLAUDE.md or the relevant project's CLAUDE.md.

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

After committing on a branch, open a PR with `gh pr create`. Never merge to main
directly — the user reviews all code and decides when to merge.

Always rebase the branch on origin/main before submitting a PR.

Preferred merge strategy is squash merge (`--squash`).

Keep PRs small and atomic — one logical change per PR.

Before pushing new commits to a branch, check that its PR has not already been
merged (`gh pr view <number> --json state`). If it has, start a fresh branch
from origin/main instead.

## CLAUDE.md Maintenance

Only document project-specific conventions and decisions — not general knowledge
that Claude already knows from training (language semantics, standard tool
behavior, common patterns). If removing a note wouldn't risk a future mistake
specific to this project, don't write it.
