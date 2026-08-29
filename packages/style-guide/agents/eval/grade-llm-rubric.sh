#!/usr/bin/env bash
set -euo pipefail

GRADER_SYSTEM='You are a strict grading assistant for an automated test
harness. Respond with only one minified JSON object using this schema:
{"pass": <true|false>, "score": <number 0..1>, "reason": "<one short sentence>"}.
Set pass true only if the model output satisfies the supplied rubric.'

raw="$(claude -p --setting-sources "" --append-system-prompt "$GRADER_SYSTEM" "$@")"
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
