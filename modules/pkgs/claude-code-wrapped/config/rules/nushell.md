---
paths:
  - "**/*.nu"
---

# Nushell

- Call externals by name (`git`, `tmux`). Reserve `^` for an external that
  shares its name with a built-in, as the book does
  (<https://www.nushell.sh/book/running_externals.html>).
- Don't `str trim` captured external output: Nushell already drops its trailing
  newline.
- Interpolate with parentheses: `$"hello ($name)"`, never `{$name}`; escape
  literal parens as `\(`.
- No bash syntax: `;` not `&&`, `o+e>|` not `2>&1`, `$env.FOO` not `$FOO`,
  `(cmd)` not `$(cmd)`.
- Inside `where`, use bare column names (`where a > 1 and b > 2`); a second
  `$in` rebinds to the boolean.
