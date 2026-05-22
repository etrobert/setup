# CLAUDE.md

## About the User

Étienne Robert — software engineer with 15 years of experience, and a queer
creative (dance, sewing, makeup, aerials, and more). Uses Claude for both
software engineering and non-technical work. Tracks life documentation in
Markdown files, often located at `~/sync/doc`.

Has a GitHub Copilot Pro individual subscription (annual, ~300 premium
requests/month, resetting on the 1st).

Sews decently. IKEA Family member (Germany).

Uses Home Assistant and prefers local integrations where available.
ESPHome-based devices are a good fit. Comfortable with kit assembly and DIY
hardware. Pragmatic about warranties — willing to skip them for meaningful cost
savings.

No longer employed at Banani (as of May 2026). Currently setting up as a
freelancer in Germany — pursuing Gründungszuschuss and AVGS-Coaching through
Agentur für Arbeit. Has AXA private liability insurance (Privathaftpflicht).

## Memory

Do not use the file-based memory system. Instead, write learnings and context
into this global CLAUDE.md or the relevant project's CLAUDE.md.

## Machines

All machines are connected via Tailscale. SSH into any of them by name
(`ssh tower`, `ssh leod`, `ssh pi`) as long as Tailscale is up on the current
machine. If SSH is refused, check whether Tailscale is running
(`tailscale status`) and bring it up with `sudo tailscale-up` if needed.

## Working Style

Work on one thing at a time. When a task naturally leads to a follow-up (e.g.
removing a config after verifying a migration), open a separate PR rather than
bundling it. Present the next step and wait for confirmation before starting.

Before asking a question, check if the answer is obtainable by reading files,
running a command, or SSHing into a machine. Only ask when a reasonable
investigation wouldn't yield the answer.

## Research Approach

When investigating how something works, consult both official documentation and
source/implementation. Don't rely on only one of these.

## Running Packages

If a needed tool is not installed on the system, use `nix run nixpkgs#<package>`
rather than skipping the step.

To verify a change, either build it (`nix build`) or run it with a test
parameter (`nix run <program> -- --test-param`) — both are fine. But when
handing the user a command to execute themselves, prefer the simplest invocation
(e.g. `nix run` over `nix build` followed by `./result/bin/...`).

## Code Style

Always format, typecheck, and lint after making a change. Check the conform
config (`pkgs/neovim-wrapped/plugins/conform/config.lua`) to see which formatter
applies to a given file type. Markdown files use
`nix run nixpkgs#prettier -- --write <file>`. Format after every individual
edit, not just at the end of a session.

Prefer `kebab-case` for directory names.

## Testing

Always test that code works before committing. Run the relevant test, build, or
manual verification step first.

## Git Workflow

Run `git alias` to discover available git aliases before running git commands.

After committing on a branch, open a PR with `gh pr create`. Never merge to main
directly — the user reviews all code and decides when to merge.

Always rebase on origin/main before presenting a PR for review — both on initial
`gh pr create` and after any follow-up changes before telling the user it's
ready.

After opening a PR, always check its status
(`gh pr view --json state,mergeStateStatus`) and resolve any merge conflicts
before reporting the task as done.

Before merging, always fetch and read all review comments — never merge with
open threads. Reply to every comment: if applying a suggestion without anything
to add, say so explicitly. The user uses Conventional Comments to signal intent
(e.g. `**issue:**`, `**question:**`, `**suggestion:**`). "Reviewed" does not
mean approved — always check for open comments before merging.

Preferred merge strategy is squash merge (`--squash`). When ready to merge but
CI is still running, use `gh pr merge --squash --auto` rather than waiting.

After merging, delete the remote branch with
`git push origin --delete <branch>`.

Keep PRs small and atomic — one logical change per PR. Unrelated changes must
always be in separate PRs, even if they are small.

For complex features that naturally split into layers, use stacked PRs: each PR
builds on the previous one.

**IMPORTANT:** Before pushing new commits to a branch, always check that its PR
has not already been merged (`gh pr view <number> --json state`). If it has,
start a fresh branch from origin/main instead. Skipping this will push directly
to main.

To push a local branch to a new remote branch of the same name, use
`git push origin HEAD:<branch-name>`. Avoid `git push -u origin <branch>` on a
branch that tracks `origin/main` — it will push to main directly.

When merging a PR from inside a git worktree, `gh pr merge` fails because `main`
is already checked out in the parent worktree. Use the GitHub API instead:

```bash
gh api repos/{owner}/{repo}/pulls/{N}/merge -X PUT -f merge_method=squash
```

## CLAUDE.md Maintenance

Only document project-specific conventions and decisions — not general knowledge
that Claude already knows from training (language semantics, standard tool
behavior, common patterns). If removing a note wouldn't risk a future mistake
specific to this project, don't write it.

## Session Reflection

At the end of every session, proactively ask: are there things learned this
session worth writing down in either the global CLAUDE.md
(`/home/soft/setup/pkgs/claude-code-wrapped/config/CLAUDE.md`) or the project
CLAUDE.md — so that future sessions can know the user better or work more
efficiently? Propose specific candidates from the session. Apply the CLAUDE.md
Maintenance guidelines — only surface things that are non-obvious and genuinely
specific to the user or project. Things about the user go in the global
CLAUDE.md; project-specific workflow or conventions go in the project CLAUDE.md.
If the user approves, create a PR with the changes following the standard git
workflow.
