# CLAUDE.md

## About the User

Étienne Robert — software engineer with 15 years of experience, and a queer
creative (dance, sewing, makeup, aerials, and more). Uses Claude for both
software engineering and non-technical work. Tracks life documentation in
Markdown files at `~/sync/doc`.

On the Claude **Max** plan. Has a GitHub Copilot Pro individual subscription
(annual, ~300 premium requests/month).

Sews decently.

Lives in Berlin but does not speak German. Communicate in English and avoid
German terms in filenames or output — prefer English equivalents (e.g. "proof of
value" not "Wertnachweis"). Does not have a driver's license.

Uses Home Assistant and prefers local integrations where available. Comfortable
with kit assembly and DIY hardware.

Currently setting up as a freelancer in Germany — pursuing Gründungszuschuss and
AVGS-Coaching through Agentur für Arbeit. As of mid-2026 receives
Arbeitslosengeld I (~€2,460/mo) until December 2026. Has AXA private liability
insurance (Privathaftpflicht).

## Memory

Do not use the file-based memory system. Instead, write learnings and context
into this global CLAUDE.md or the relevant project's CLAUDE.md.

## Machines

Git repos are cloned at `~/work/*`, except for the setup repo which lives at
`~/setup`.

All machines are connected via Tailscale. SSH into any of them by name
(`ssh tower`, `ssh leod`, `ssh pi`) as long as Tailscale is up on the current
machine.

## Simplicity First

Favor simplicity over completeness — across code, design, CI, tooling, and
process, not just code. Prefer the simplest solution that solves the problem;
when fully solving it would take disproportionate complexity, prefer a simpler
solution that handles the common case (and flag what it leaves out) over a
complex one that covers everything. Before treating anything as done, ask "can
this be simpler?" and cut whatever isn't earning its place; prefer a plain
solution a reader grasps immediately over a clever one.

## Communication

When you use an acronym for the first time, spell it out.

## Working Style

Before asking a question, check if the answer is obtainable by reading files,
running a command, or SSHing into a machine. Only ask when a reasonable
investigation wouldn't yield the answer.

Don't be afraid to make multiple different implementations of the same feature
to compare them.

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

## Code Style

Prefer `kebab-case` for directory names.

In shell scripts, prefer long-form parameters over single-letter ones where
possible (e.g. `--raw-output` over `-r`, `--only-matching` over `-o`).

Separate multi-line definitions/blocks with a blank line. Consecutive
single-line bindings may be grouped together without blank lines, but a
definition that spans multiple lines should be set off by a blank line before
and after it — don't butt a multi-line binding (e.g. `runtimeInputs = [ … ]`)
directly against an adjacent definition.

In Tailwind, prefer the predefined scale (`text-lg`, `rounded-md`, `p-2.5`) over
arbitrary values (`text-[1.1rem]`, `rounded-[0.4rem]`), snapping to the nearest
step rather than preserving an exact number. Reserve `[…]` for values with no
scale equivalent — custom properties (`rotate-[var(--rot)]`), grid templates,
property lists.

## Documentation & Notes

When writing docs, notes, or comments, state only what's true now. Don't record
obsolete or superseded information — e.g. after moving a file, just give the new
path; don't note where it used to live or that an old copy is "superseded." Such
references are dead text that add noise without value.

Keep code comments minimal. State only the single non-obvious points and leave
narrative context (root-cause chains, incident history) for the commit or PR.

## Testing

Before committing, verify the change: typecheck, lint, and run the relevant
test, build, or manual verification step.

## GitHub Identity

Claude Code has its own GitHub account (`etrobert-bot`) and must use it for all
GitHub operations — never impersonate the user (`etrobert`). If a permission is
missing (e.g. `etrobert-bot` is not a collaborator on a repo), ask the user to
grant it rather than attempting to act as them.

## Git Workflow

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

Always resolve merge conflicts before reporting the task as done.

To review, use Conventional Comments.

To follow up on a review, reply to every comment: if applying a suggestion
without anything to add, say so explicitly.

Preferred merge strategy is squash merge (`--squash`).

Keep PRs small and atomic — one logical change per PR.

For complex features that naturally split into layers, use stacked PRs: each PR
builds on the previous one.

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
