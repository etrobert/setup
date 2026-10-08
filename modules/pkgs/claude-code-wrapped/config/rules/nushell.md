---
paths:
  - "**/*.nu"
---

# Nushell

- Call externals by name (`git`, `tmux`). Reserve `^` for an external that
  shares its name with a built-in, as the book does
  (<https://www.nushell.sh/book/running_externals.html>).
- Prefer built-ins over external tools for data: `http`, `open`, records and
  tables rather than `curl` and `jq`.
