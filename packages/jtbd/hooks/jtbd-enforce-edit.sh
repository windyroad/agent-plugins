#!/bin/bash
# JTBD - PreToolUse enforcement hook
# BLOCKS Edit/Write to project files until jtbd-lead is consulted.
# Supports both docs/jtbd/ directory (preferred) and docs/JOBS_TO_BE_DONE.md (legacy).
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

# P004: Only gate files inside the project root. Absolute paths outside
# $PWD (e.g., ~/.claude/channels/*) are not project files.
case "$FILE_PATH" in
  /*)
    case "$FILE_PATH" in
      "$PWD"/*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

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
  */docs/jtbd/*|docs/jtbd/*)
    exit 0 ;;
  */docs/JOBS_TO_BE_DONE.md|docs/JOBS_TO_BE_DONE.md)
    exit 0 ;;
  */docs/PRODUCT_DISCOVERY.md|docs/PRODUCT_DISCOVERY.md)
    exit 0 ;;
esac

# Determine JTBD path — prefer directory, fall back to single file
JTBD_PATH=""
if [ -d "docs/jtbd" ]; then
  JTBD_PATH="docs/jtbd"
elif [ -f "docs/JOBS_TO_BE_DONE.md" ]; then
  JTBD_PATH="docs/JOBS_TO_BE_DONE.md"
fi

# If no JTBD docs exist, block and direct to create skill
if [ -z "$JTBD_PATH" ]; then
  review_gate_deny "BLOCKED: Cannot edit '${BASENAME}' because no JTBD documentation exists. Run /wr-jtbd:update-guide to generate JTBD docs for this project, then delegate to wr-jtbd:agent for review."
  exit 0
fi

# Check gate with TTL + drift detection
if check_review_gate "$SESSION_ID" "jtbd" "$JTBD_PATH"; then
  exit 0
fi

review_gate_deny "BLOCKED: Cannot edit '${BASENAME}' without JTBD review. You MUST first delegate to wr-jtbd:agent using the Agent tool (subagent_type: 'wr-jtbd:agent'). ${REVIEW_GATE_REASON}"
exit 0
