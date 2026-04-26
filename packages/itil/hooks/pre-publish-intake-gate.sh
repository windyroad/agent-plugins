#!/bin/bash
# PreToolUse:Bash hook (P065 / ADR-036 Trigger 2): blocks `npm publish`
# and `gh pr merge` of a `changeset-release/*` PR when the project is
# missing one or more of the five intake files.
#
# Required intake files (per ADR-036 Detection step 5):
#   .github/ISSUE_TEMPLATE/config.yml
#   .github/ISSUE_TEMPLATE/problem-report.yml
#   SECURITY.md
#   SUPPORT.md
#   CONTRIBUTING.md
#
# Bypass / opt-out paths (in priority order, per architect direction):
#   1. INTAKE_BYPASS=1 in env       -> short-circuit BEFORE existence check
#                                      (consistent with RISK_BYPASS naming
#                                      convention in external-comms-gate.sh)
#   2. .claude/.intake-scaffold-declined marker present -> permit
#                                      (ADR-009 marker semantics; explicit
#                                      decline by adopter, persistent until
#                                      file deleted)
#   3. All five intake files present -> permit (idempotent default)
#   4. Otherwise                    -> deny + delegate to /wr-itil:scaffold-intake
#
# This hook composes with risk-scorer's git-push-gate.sh: both fire on
# Bash with `gh pr merge` matchers, and either may deny independently.
# In practice git-push-gate denies all `gh pr merge` and routes to
# `npm run release:watch` which subsequently runs `npm publish` — at
# which point this hook fires.

set -euo pipefail

# ---------- 1. Bypass: check INTAKE_BYPASS BEFORE anything else ----------
if [ "${INTAKE_BYPASS:-0}" = "1" ]; then
    exit 0
fi

INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Out of scope: only Bash invocations are gated.
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# ---------- Surface detection ----------
IN_SCOPE=0

# Match `npm publish` (with or without flags).
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*npm publish(\s|$)'; then
    IN_SCOPE=1
fi

# Match `gh pr merge` against a changeset-release/* PR. The changesets
# release-PR pattern is the only `gh pr merge` shape that flips the
# publish boundary. A regular feature-branch merge does not.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh pr merge\b' \
   && echo "$COMMAND" | grep -qE 'changeset-release/'; then
    IN_SCOPE=1
fi

[ "$IN_SCOPE" = "1" ] || exit 0

# ---------- 2. Decline marker (ADR-009 persistent marker) ----------
if [ -f ".claude/.intake-scaffold-declined" ]; then
    exit 0
fi

# ---------- 3. Intake-file existence check ----------
MISSING=()
for path in \
    ".github/ISSUE_TEMPLATE/config.yml" \
    ".github/ISSUE_TEMPLATE/problem-report.yml" \
    "SECURITY.md" \
    "SUPPORT.md" \
    "CONTRIBUTING.md"; do
    if [ ! -f "$path" ]; then
        MISSING+=("$path")
    fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then
    exit 0
fi

# ---------- 4. Deny + delegate ----------
deny_reason() {
    local missing_list
    missing_list=$(printf '  - %s\n' "${MISSING[@]}")
    cat <<EOF
BLOCKED (P065 / ADR-036 pre-publish intake gate): ${#MISSING[@]} of 5 intake files missing — downstream reporters would hit a blank issue form and have no declared security-disclosure channel.

Missing:
${missing_list}

Recovery, in priority order:
  1. Run /wr-itil:scaffold-intake to scaffold the missing intake files (recommended for first-time adopters).
  2. Set INTAKE_BYPASS=1 to override for documented exceptions:
       INTAKE_BYPASS=1 npm publish
  3. Decline scaffolding entirely (suppresses the gate indefinitely):
       mkdir -p .claude && touch .claude/.intake-scaffold-declined
EOF
}

REASON=$(deny_reason)

python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'deny',
        'permissionDecisionReason': sys.argv[1]
    }
}))
" "$REASON"

exit 0
