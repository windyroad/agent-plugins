#!/usr/bin/env bash
# Codex grading-provider driver for promptfoo llm-rubric assertions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
SCHEMA="${SCRIPT_DIR}/codex-rubric-output.schema.json"
PROMPT="${*:-}"

if [[ -z "$PROMPT" ]]; then
  echo "grade-codex-rubric.sh: rubric prompt argument is required" >&2
  exit 2
fi

GRADER_SYSTEM='You are a strict grading assistant for an automated promptfoo test. Respond with only JSON matching the provided schema. Set pass true only if the model output satisfies the rubric. Be literal about negation.'

raw="$(
  codex exec \
    --ephemeral \
    --cd "$REPO_ROOT" \
    -c 'approval_policy="never"' \
    --sandbox read-only \
    --output-schema "$SCHEMA" \
    "${GRADER_SYSTEM}

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
