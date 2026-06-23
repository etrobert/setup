# CLAUDE.md

## About the User

Étienne Robert — software engineer with 15 years of experience, and a queer
creative (dance, sewing, makeup, aerials, and more). Uses Claude for both
software engineering and non-technical work. Tracks life documentation in
Markdown files, often located at `~/sync/doc`.

On the Claude **Max** plan. Has a GitHub Copilot Pro individual subscription
(annual, ~300 premium requests/month). Has a GLM Pro subscription (z.ai)
powering the `claude-glm` / `claude-code-wrapped-glm` backend.

Sews decently. IKEA Family member (Germany).

Lives in Berlin but does not speak German. Communicate in English and avoid
German terms in filenames or output — prefer English equivalents (e.g. "proof of
value" not "Wertnachweis"). Does not have a driver's license.

Uses Home Assistant and prefers local integrations where available.
ESPHome-based devices are a good fit. Comfortable with kit assembly and DIY
hardware. Pragmatic about warranties — willing to skip them for meaningful cost
savings.

Currently setting up as a freelancer in Germany — pursuing Gründungszuschuss and
AVGS-Coaching through Agentur für Arbeit. Has AXA private liability insurance
(Privathaftpflicht).

## Memory

Do not use the file-based memory system. Instead, write learnings and context
into this global CLAUDE.md or the relevant project's CLAUDE.md.

## Machines

Git repos are cloned at `~/work/*`, except for the setup repo which lives at
`~/setup`.

All machines are connected via Tailscale. SSH into any of them by name
(`ssh tower`, `ssh leod`, `ssh pi`) as long as Tailscale is up on the current
machine. If SSH is refused, check whether Tailscale is running
(`tailscale status`) and bring it up with `sudo tailscale-up` if needed.

## Working Style

Before asking a question, check if the answer is obtainable by reading files,
running a command, or SSHing into a machine. Only ask when a reasonable
investigation wouldn't yield the answer.

## Research Approach

When investigating how something works, consult both official documentation and
source/implementation. Don't rely on only one of these.

Cite the source for factual claims — name and, where useful, quote or link the
command, `--help` output, web search result, documentation page (with URL), or
file the information came from, rather than stating it unsourced.

## Exploring External Code

To understand how a tool or library works, you're encouraged to clone its repo
and read the source — don't rely on docs alone. Clone into `~/.cache/explore/`
(create it if needed).

## Running Packages

If a needed tool is not installed on the system, use `nix run nixpkgs#<package>`
rather than skipping the step.

To verify a change, either build it (`nix build`) or run it with a test
parameter (`nix run <program> -- --test-param`) — both are fine. But when
handing the user a command to execute themselves, prefer the simplest invocation
(e.g. `nix run` over `nix build` followed by `./result/bin/...`).

## Nix Style

Prefer flake-native Nix over legacy invocations. Examples:

- `nix run nixpkgs#foo` over `nix-shell -p foo --run` or `nix-env -iA`
- `nix eval nixpkgs#attr --apply <fn>` over
  `nix eval --impure --expr 'with import <nixpkgs> {}; ...'`
- `nix shell nixpkgs#foo` over `nix-shell -p foo`
- `nix build .#pkg` over `nix-build`

Avoid `with import <nixpkgs> {}` and `<nixpkgs>` channel lookups in commands —
use `nixpkgs#` flake refs and `--apply` to transform results.

When embedding another language inside a plain Nix string, add a language hint
comment so the editor injects syntax highlighting. Example:

```nix
linuxPrimitives = /* bash */ ''
  notify() { notify-send "$1" "$2"; }
'';
```

Skip it when nvim-treesitter's Nix injection queries already cover the attr name
— e.g. `writeShellApplication`/`writeShellScript` text attrs, or
`stdenv.mkDerivation` phase hooks (`*Phase`, `pre*`, `post*` — like
`buildPhase`, `postInstall`). All defined in `queries/nix/injections.scm`.

## Code Style

Default to simple code over feature-rich code. Build the minimal thing that
solves the problem at hand; additional functionality can always be added later
when it's actually needed.

Prefer `kebab-case` for directory names.

In shell scripts, prefer long-form parameters over single-letter ones where
possible (e.g. `--raw-output` over `-r`, `--only-matching` over `-o`).

Separate multi-line definitions/blocks with a blank line. Consecutive
single-line bindings may be grouped together without blank lines, but a
definition that spans multiple lines should be set off by a blank line before
and after it — don't butt a multi-line binding (e.g. `runtimeInputs = [ … ]`)
directly against an adjacent definition.

## Testing

Before committing, verify the change: typecheck, lint, and run the relevant
test, build, or manual verification step.

## GitHub Identity

Claude Code has its own GitHub account (`etrobert-bot`) and must use it for all
GitHub operations — never impersonate the user (`etrobert`). If a permission is
missing (e.g. `etrobert-bot` is not a collaborator on a repo), ask the user to
grant it rather than attempting to act as them.

## Git Workflow

After committing on a branch, open a PR with `gh pr create`.

When a PR makes a user-visible change (UI, status-bar/terminal styling, CLI
output), include a screenshot in the PR description.

When rendering a terminal-UI screenshot headlessly (xterm under Xvfb), load the
terminal theme's 16-color ANSI palette into xterm
(`-xrm 'xterm*color4: #8aadf4' …`) — otherwise palette references like
`colour4`/`colour0` render as harsh xterm defaults instead of the real theme
colors.

Each commit should be functional — don't commit broken or speculative states.

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

At the end of every session, proactively propose any non-obvious, durable
learnings worth recording — user facts to the global CLAUDE.md, project
conventions to the project CLAUDE.md — following the Maintenance guidelines
above. If the user approves, open a PR per the standard git workflow.
