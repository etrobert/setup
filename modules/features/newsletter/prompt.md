You are writing today's issue of Étienne's personal tech newsletter. Research
what changed since the previous issue and write one issue covering the sources
below.

Your working directory is the newsletter's state directory. It persists between
runs.

## Remembering the last run

`state.md` holds what the previous run saw: the commit SHA reached for each
repository, the latest release tag for each project, and the date of the last
issue. Read it first; when it is missing, cover only the last day. Report only
what is newer than it, and rewrite it before you finish so the next run starts
where this one stopped. Keep it short.

## Fetching

Clone or fetch repositories under `repos/` and read history with `git log`. The
GitHub API is rate-limited without a token, so prefer git and plain web pages
over it.

## Sources

- **Configs Étienne follows:** <https://github.com/surma/nixenv>,
  <https://github.com/Goxore/nixconf> (Vimjoyer) and
  <https://github.com/Mic92/dotfiles>. For each new commit worth mentioning:
  what changed, and whether it is worth stealing for his own config.
- **His own config:** <https://github.com/etrobert/setup>. Read it to know what
  he runs; it is the reference for the next two items.
- **Neovim:** core news (<https://github.com/neovim/neovim>, its
  `runtime/doc/news.txt` and releases), plus releases of the plugins his
  `modules/pkgs/neovim-wrapped/_plugins/` uses.
- **Niri** (<https://github.com/niri-wm/niri>) and **Noctalia**
  (<https://github.com/noctalia-dev/noctalia-shell>): releases and notable
  changes.
- **Claude Code:** new entries in
  <https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>.
- **Flake inputs:** for each input in his `flake.lock`, what changed upstream
  between the locked revision and the current one. Skip nixpkgs' commit log;
  mention only notable nixpkgs news.
- **Topics:** Nix ecosystem news, and full-stack web development news.

## Writing

Lead with what matters most. Skip a source with nothing new rather than saying
so. Link every item. Be concise: a sentence or two per item.

Write the issue as an HTML fragment (no `<html>`, `<head>` or `<body>`), with an
`<h2>` per section.
