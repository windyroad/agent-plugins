#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
SCHEMA="${SCRIPT_DIR}/codex-rubric-output.schema.json"
PROMPT="${*:-}"

if [[ -z "$PROMPT" ]]; then
  echo "grade-codex-rubric.sh: rubric prompt argument is required" >&2
  exit 2
fi

raw="$(
  codex exec \
    --ephemeral \
    --cd "$REPO_ROOT" \
    -c 'approval_policy="never"' \
    --sandbox read-only \
    --output-schema "$SCHEMA" \
    "You are a strict grading assistant. Respond only with JSON matching the provided schema. Grade this promptfoo rubric literally.

${PROMPT}"
)"

printf '%s' "$raw" | awk '
  BEGIN { depth = 0; started = 0 }
  {
    line = $0
    for (i = 1; i <= length(line); i++) {
      c = substr(line, i, 1)
      if (c == "{") { depth++; started = 1 }
      if (started) { buf = buf c }
      if (c == "}") { depth--; if (depth == 0 && started) { print buf; exit } }
    }
    if (started) { buf = buf "\n" }
  }
  END { if (started && depth != 0) print buf }
' || printf '%s' "$raw"
