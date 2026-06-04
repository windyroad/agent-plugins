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
    "permissionDecisionReason": "BLOCKED: Architect must review the plan file before exiting plan mode. You MUST first delegate to wr-architect:agent using the Agent tool (subagent_type: 'wr-architect:agent') to review the plan against existing decisions in docs/decisions/. After the review completes, this will be unblocked automatically."
  }
}
EOF
exit 0
