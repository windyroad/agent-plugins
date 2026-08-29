#!/usr/bin/env bash
set -euo pipefail

SYSTEM_PROMPT='Return only minified JSON matching {"pass":boolean,"score":number,"reason":string}. Grade the supplied response literally against the rubric, including negation.'
raw="$(claude -p --append-system-prompt "$SYSTEM_PROMPT" "$@")"

printf '%s' "$raw" | awk '
  BEGIN { depth = 0; started = 0 }
  {
    for (i = 1; i <= length($0); i++) {
      c = substr($0, i, 1)
      if (c == "{") { depth++; started = 1 }
      if (started) { buf = buf c }
      if (c == "}") { depth--; if (depth == 0 && started) { print buf; exit } }
    }
    if (started) { buf = buf "\n" }
  }
  END { if (started && depth != 0) print buf }
' || printf '%s' "$raw"
