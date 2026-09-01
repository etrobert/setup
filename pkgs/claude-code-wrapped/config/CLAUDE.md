# CLAUDE.md

## About the User

Étienne Robert — software engineer with 15 years of experience, and a queer
creative (dance, sewing, makeup, aerials, and more). Uses Claude for software
engineering and non-technical work. Tracks life documentation in Markdown files
at `~/sync/doc`.

On the Claude Max x20 plan.

Lives in Berlin but does not speak German. Does not have a driver's license.

Uses Home Assistant and prefers local integrations where available. Comfortable
with kit assembly and DIY hardware.

Currently setting up as a freelancer in Germany. Has AXA private liability
insurance (Privathaftpflicht).

Rents in Berlin-Neukölln and is a member of the Berliner Mieterverein, so
tenant-law advice is available for rental disputes.

## Machines

Git repos are bare cloned at `~/work/*` with `git-project-clone`.

All machines are connected via Tailscale. SSH into any of them by name
(`ssh tower`, `ssh leod`, `ssh pi`) as long as Tailscale is up on the current
machine.

## Simplicity First

- Always build simple. We can always add features later.
- Prefer the simplest solution that solves the problem, the MVP.
- Being able to read and understand a code at a glance is important to me.
  - Prefer a plain solution over a clever one.

As the final pass before presenting any work — code, config, docs, plans, PRs —
go element by element (parameter, option, line, section, step) and attempt to
delete it. Keep an element only when you can state concretely what its removal
breaks or loses, verified against the authoritative source (the actual default,
the actual caller, the actual reader's need) rather than from memory. Removal is
the default.

## Communication & Working Style

When you use an acronym for the first time, spell it out.

Before asking a question, check if the answer is obtainable by reading files,
running a command, or SSHing into a machine. Only ask when a reasonable
investigation wouldn't yield the answer.

Don't be afraid to make multiple different implementations of the same feature
to compare them.

Always spell out links. Don't use
[the repo](https://www.github.com/etrobert/setup) but use
<https://www.github.com/etrobert/setup>. I am often working over ssh and
clicking the links open on the wrong machine.

## Research Approach

When investigating how something works, consult both official documentation and
source/implementation.

Cite the source for factual claims — name and, where useful, quote or link the
command, `--help` output, web search result, documentation page (with URL), or
file the information came from, rather than stating it unsourced.

To understand how a tool or library works, you're encouraged to clone its repo
and read the source — don't rely on docs alone. Clone into `~/.cache/explore/`
(create it if needed).

## Running Packages

If a needed tool is not installed on the system, use `nix run nixpkgs#<package>`
rather than skipping the step.

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
comment so that treesitter understands it. Example:

```nix
linuxPrimitives = /* bash */ ''
  notify() { notify-send "$1" "$2"; }
'';
```

## Code Style

Prefer `kebab-case` for directory names.

In shell scripts and expressions, prefer long-form parameters over single-letter
ones where possible (e.g. `--raw-output` over `-r`, `--only-matching` over
`-o`).

Prefer failing loudly. A panic or hard error surfaces a broken assumption when
it breaks; a fallback defers it into a wrong answer later. Never convert an
existing `expect`/`panic!`, or any other deliberate hard failure, into a default
value.

In Tailwind, prefer the predefined scale (`text-lg`, `rounded-md`, `p-2.5`) over
arbitrary values (`text-[1.1rem]`, `rounded-[0.4rem]`), snapping to the nearest
step rather than preserving an exact number. Reserve `[…]` for values with no
scale equivalent — custom properties (`rotate-[var(--rot)]`), grid templates,
property lists.

## File Edits

Use the Write/Edit tools for source files rather than Bash heredocs or `sed -i`,
including in bypass-permissions mode where the default guidance prefers Bash.
The `PostToolUse` hook running `format-file` matches only
`Edit|Write|MultiEdit`, so Bash writes skip formatting entirely, and Write's
refusal to overwrite an unread file is the only guard against clobbering hand
edits made between steps.

## Documentation & Notes

When writing docs, notes, or comments, state only what's true now. Don't record
obsolete or superseded information — e.g. after moving a file, just give the new
path; don't note where it used to live or that an old copy is "superseded." Such
references are dead text that add noise without value.

Keep code comments minimal and short — one line, two at most. Longer belongs in
the commit or PR, as does narrative context (root-cause chains, incident
history). Neighbouring files' comment density is not a justification.

Before writing one, cover it: if a reader could recover it from the code — the
name, the expression below, the message it carries, the helper it calls — cut
it. Most often that is one narrating work you just did. It earns its place only
by carrying what the code cannot: why this value, which upstream bug.

## Testing

Before committing, verify the change: typecheck, lint, and run the relevant
test, build, or manual verification step.

## Git Workflow

When a PR makes a user-visible change (UI, status-bar/terminal styling, CLI
output), include a screenshot in the PR description.

When rendering a terminal-UI screenshot headlessly (xterm under Xvfb), load the
terminal theme's 16-color ANSI palette into xterm
(`-xrm 'xterm*color4: #8aadf4' …`) — otherwise palette references like
`colour4`/`colour0` render as harsh xterm defaults instead of the real theme
colors.

Attach that screenshot the way the web textarea does — the endpoint behind
paste-into-comment takes a `gh` token:

```bash
curl --request POST --header "Authorization: Bearer $(gh auth token)" \
  --data-binary @shot.png \
  "https://uploads.github.com/user-attachments/assets?name=shot.png&content_type=image/png&repository_id=$(gh api repos/OWNER/REPO --jq .id)"
```

Put the returned `github.com/user-attachments/assets/<uuid>` in the PR body. It
404s on a direct fetch — GitHub mints a short-lived signed URL at render time,
for anonymous viewers too — so don't take that 404 as a failed upload. The
endpoint is undocumented and `gh` has no native support; scp to
`tower:/srv/files/ci/` (served at `files.etiennerobert.com/ci/`) is the fallback
when a directly-fetchable URL is needed. That directory is public and browsable,
so keep private content out of anything uploaded there.

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

- User `CLAUDE.md` : Only document conventions, decisions, and preferences
  specific to **me** and how **I** work.
- Project `CLAUDE.md` :Only document conventions, decisions, and preferences
  specific to **this project**.
- Never document general knowledge that Claude already knows from training
  (language semantics, standard tool behavior, common patterns) or informations
  relating to how other projects work (eg. neovim conventions or details on how
  to use).
- If removing a note wouldn't risk a future mistake specific to this project,
  don't write it.
- At the end of every session, reflect and proactively propose enhancements to
  the user `CLAUDE.md` and project `CLAUDE.md` following the Maintenance
  guidelines above.
