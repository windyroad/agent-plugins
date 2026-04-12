#!/bin/bash
# PostToolUse:Skill hook — sets a marker when /wr-tdd:setup-tests is invoked.
# This marker allows tdd-enforce-edit.sh to permit edits during test setup,
# avoiding the chicken-and-egg problem where the setup skill needs to write
# .ts/.js files but the enforce hook blocks them.

INPUT=$(cat)

SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$SESSION_ID" ] || [ -z "$SKILL_NAME" ]; then
  exit 0
fi

# Match the TDD setup skill (handles both full and short names)
case "$SKILL_NAME" in
  *tdd*setup*|*setup*test*)
    touch "/tmp/tdd-setup-active-${SESSION_ID}"
    ;;
esac

exit 0
