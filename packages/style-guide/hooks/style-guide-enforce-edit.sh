#!/bin/bash
# Style Guide - PreToolUse enforcement hook
# BLOCKS Edit/Write to UI source files until style-guide-lead is consulted.
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

# Gate all UI source files (CSS and component files)
case "$FILE_PATH" in
  *.css|*.html|*.jsx|*.tsx|*.vue|*.svelte|*.ejs|*.hbs) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")

# If no policy file exists, block and direct to create skill
if [ ! -f "docs/STYLE-GUIDE.md" ]; then
  review_gate_deny "BLOCKED: Cannot edit '${BASENAME}' because docs/STYLE-GUIDE.md does not exist. Run /wr-style-guide:update-guide to generate a style guide for this project, then delegate to wr-style-guide:agent for review."
  exit 0
fi

# Check gate with TTL + drift detection
if check_review_gate "$SESSION_ID" "style-guide" "docs/STYLE-GUIDE.md"; then
  exit 0
fi

review_gate_deny "BLOCKED: Cannot edit '${BASENAME}' without style guide review. You MUST first delegate to wr-style-guide:agent using the Agent tool (subagent_type: 'wr-style-guide:agent'). ${REVIEW_GATE_REASON}"
exit 0
