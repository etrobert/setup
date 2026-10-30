---
name: claude-md-maintenance
description:
  Checks candidate CLAUDE.md additions against Étienne's rules before they are
  shown or written. Use before proposing, suggesting or writing any change to
  the user or a project CLAUDE.md, including end-of-session reflections.
---

# CLAUDE.md maintenance

## Rules

- User `CLAUDE.md`: only conventions, decisions and preferences specific to
  Étienne's way of working.
- Project `CLAUDE.md`: only conventions, decisions and preferences specific to
  that project.
- Never general knowledge Claude has from training (language semantics, standard
  tool behavior, common patterns), nor how other projects work (e.g. neovim
  conventions, how to use a tool).
- If removing a note wouldn't risk a future mistake specific to this project,
  don't write it.

## Before proposing anything

1. Search both the user `CLAUDE.md` and the project `CLAUDE.md` for text that
   already covers the candidate.
2. Give each candidate a verdict against every rule above.
3. Show only the candidates that pass. When none pass, say so in one line —
   proposing nothing is the common outcome.
