#!/bin/bash
# TDD - PostToolUse hook (Edit|Write) - review-test advisory
# Per ADR-052 (Behavioural-tests-default for skill testing).
#
# When a test-shaped file is written, emit additionalContext directing the
# assistant to invoke the review-test agent. The hook never blocks; it is
# advisory-only in this Phase. Phase-2 promotion to PreToolUse blocking is
# tracked in ADR-052 reassessment criteria.
#
# Returns silent on:
# - Non-test file extension (.sh, .ts impl, .md, etc.)
# - Path outside $PWD (avoids classifying tests in node_modules, vendored libs)
# - Env var WR_TDD_REVIEW_TEST=skip set (ADR-044 category 3 override)
# - File contains `tdd-review: structural-permitted` comment (ADR-044 category 2)
# - File does not yet exist (Edit on a path that hasn't been written)

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty') || true

# No file path → nothing to classify.
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Surface 1 escape hatch — env-var skip per ADR-044 category 3.
if [ "${WR_TDD_REVIEW_TEST:-}" = "skip" ]; then
  exit 0
fi

# Outside-PWD check — avoid classifying vendored / node_modules tests.
case "$FILE_PATH" in
  "$PWD"/*) ;;
  *) exit 0 ;;
esac

# Test-shape file extension recognition.
# Recognised shapes: bats, vitest/jest/mocha (.test.* / .spec.*), cucumber
# (.feature), pytest (test_*.py / *_test.py), go (*_test.go), ruby
# (*_test.rb / *_spec.rb).
is_test_file() {
  local p="$1"
  local base
  base=$(basename "$p")
  case "$base" in
    *.bats) return 0 ;;
    *.feature) return 0 ;;
    *.test.ts|*.test.tsx|*.test.js|*.test.jsx|*.test.mjs|*.test.cjs) return 0 ;;
    *.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx|*.spec.mjs|*.spec.cjs) return 0 ;;
    *.test.py|*.spec.py) return 0 ;;
    test_*.py|*_test.py) return 0 ;;
    *_test.go) return 0 ;;
    *_test.rb|*_spec.rb) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_test_file "$FILE_PATH"; then
  exit 0
fi

# File-not-yet-on-disk → bail. The PreToolUse-Edit-on-new-file case is rare
# but the agent has nothing to read until the Write completes.
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Surface 2 escape hatch — in-file justification comment per ADR-044 category 2.
# Recognise both `# tdd-review: …` (bash / pytest / cucumber) and
# `// tdd-review: …` (vitest / jest / mocha / TypeScript).
if grep -qE '^[[:space:]]*(#|//)[[:space:]]*tdd-review:[[:space:]]*structural-permitted' "$FILE_PATH"; then
  exit 0
fi

# Emit advisory directive — the assistant should invoke the review-test agent.
cat <<EOF
TDD REVIEW-TEST ADVISORY (per ADR-052):

A test file was just written:
  ${FILE_PATH}

Before continuing, invoke the review-test agent to classify the test as
behavioural or structural:

  Use the Agent tool with subagent_type 'wr-tdd:review-test' (or the
  equivalent agent invocation surface for your harness) and pass the
  test file path.

The agent will return a JSON verdict with fields {verdict, evidence,
suggestion, harness_gap}. If the verdict is 'structural', either:

  1. Replace the structural assertions with behavioural ones using the
     suggestion as a starting point, OR
  2. Add a comment like:
       # tdd-review: structural-permitted (justification: <ticket-ID>
       <reason>)
     citing a specific P012-descendant harness-gap ticket per ADR-052
     Surface 2.

To skip review for this session (ADR-044 category 3 strategic override),
set WR_TDD_REVIEW_TEST=skip in the environment.
EOF

exit 0
