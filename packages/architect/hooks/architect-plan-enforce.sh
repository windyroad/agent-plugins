#!/bin/bash
# Architecture - PreToolUse enforcement hook for ExitPlanMode
# BLOCKS ExitPlanMode until architect has reviewed the plan against ADRs.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/architect-gate.sh"

# P191 Phase 2: anchor docs/decisions on the project root, not the hook's
# runtime CWD (see architect-enforce-edit.sh). This gate also fails OPEN on a
# missing decisions dir, so the CWD misfire silently lets ExitPlanMode through
# without architect plan review.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$SESSION_ID" ]; then
  architect_gate_parse_error
  exit 0
fi

# Only gate if the project has architecture decisions
if [ ! -d "$PROJECT_DIR/docs/decisions" ]; then
  exit 0
fi

# Check gate
if check_architect_gate "$SESSION_ID"; then
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Architect must review the plan file before exiting plan mode. Use the request-preparation and completion contract in /wr-architect:review-design and its runtime-native wr-architect:agent path to review the plan against existing decisions in docs/decisions/. A bound, structurally complete PASS may create a review receipt. Missing or malformed mechanical evidence remains advisory and does not waive substantive review obligations or known findings. ${ARCHITECT_GATE_REASON}"
  }
}
EOF
exit 0
