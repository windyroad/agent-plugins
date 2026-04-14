#!/bin/bash
# JTBD - PreToolUse enforcement hook
# BLOCKS Edit/Write to project files until jtbd-lead is consulted.
# Uses shared review-gate.sh for TTL, drift detection, and fail-closed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/review-gate.sh"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

SESSION_ID=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('session_id', ''))
except:
    print('')
" 2>/dev/null || echo "")

if [ -z "$SESSION_ID" ]; then
  review_gate_parse_error
  exit 0
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

# Exclude non-JTBD files (matches architect gate exclusions)
case "$FILE_PATH" in
  *.css|*.scss|*.sass|*.less)
    exit 0 ;;
  *.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico|*.webp)
    exit 0 ;;
  *.woff|*.woff2|*.ttf|*.eot)
    exit 0 ;;
  *package-lock.json|*yarn.lock|*pnpm-lock.yaml)
    exit 0 ;;
  *.map)
    exit 0 ;;
  *.changeset/*.md|*/.changeset/*.md)
    exit 0 ;;
  */MEMORY.md|*/.claude/projects/*/memory/*)
    exit 0 ;;
  */.claude/plans/*.md|*.claude/plans/*.md)
    exit 0 ;;
  */RISK-POLICY.md)
    exit 0 ;;
  */.risk-reports/*)
    exit 0 ;;
  */docs/BRIEFING.md|docs/BRIEFING.md)
    exit 0 ;;
  */docs/problems/*.md|docs/problems/*.md)
    exit 0 ;;
esac

# If no JTBD doc exists, block and direct to create skill
if [ ! -f "docs/JOBS_TO_BE_DONE.md" ]; then
  review_gate_deny "BLOCKED: Cannot edit '${BASENAME}' because docs/JOBS_TO_BE_DONE.md does not exist. Run /wr-jtbd:update-guide to generate a JTBD document for this project, then delegate to wr-jtbd:agent for review."
  exit 0
fi

# Check gate with TTL + drift detection
if check_review_gate "$SESSION_ID" "jtbd" "docs/JOBS_TO_BE_DONE.md"; then
  exit 0
fi

review_gate_deny "BLOCKED: Cannot edit '${BASENAME}' without JTBD review. You MUST first delegate to wr-jtbd:agent using the Agent tool (subagent_type: 'wr-jtbd:agent'). ${REVIEW_GATE_REASON}"
exit 0
