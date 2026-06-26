{
  writeShellApplication,
  ormolu,
  gnused,
  coreutils,
}:

# A .tidal file is a sequence of GHCi statements separated by blank lines
# (vim-tidal's block convention), not a Haskell module -- so a whole-file
# Haskell formatter chokes on it. Format each blank-separated block on its own.
writeShellApplication {
  name = "tidal-fmt";

  runtimeInputs = [
    ormolu
    gnused
    coreutils
  ];

  inheritPath = false;

  text = /* bash */ ''
    # Format one block:
    #   1. bare ormolu -- correct for simple/adjacent top-level statements;
    #   2. else wrap as an indented binding so column-1 continuations (a `]`
    #      or `#` closing a multi-line pattern) parse, format, then unwrap;
    #   3. else emit unchanged (GHCi `:t`/`:set` lines, anything unparseable).
    fmt_block() {
      local block="$1" out

      if out=$(printf '%s\n' "$block" | ormolu --stdin-input-file b.hs 2>/dev/null) \
        && [[ -n "$out" ]]; then
        printf '%s' "$out"
        return
      fi

      if out=$(printf '_w_ =\n%s\n' "$(printf '%s\n' "$block" | sed 's/^/  /')" \
        | ormolu --stdin-input-file w.hs 2>/dev/null) && [[ -n "$out" ]]; then
        printf '%s\n' "$out" | tail --lines=+2 | sed 's/^  //'
        return
      fi

      printf '%s\n' "$block"
    }

    # Read stdin, format each block, rejoin with exactly one blank line between.
    block=""
    first=1

    flush() {
      [[ -z "$block" ]] && return
      local out
      out=$(fmt_block "$block") # command substitution strips trailing newlines
      if [[ $first -eq 0 ]]; then printf '\n\n'; fi
      printf '%s' "$out"
      first=0
      block=""
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ -z "$line" ]]; then
        flush
      else
        block+="''${block:+$'\n'}$line"
      fi
    done
    flush

    if [[ $first -eq 0 ]]; then printf '\n'; fi # single trailing newline
  '';
}
