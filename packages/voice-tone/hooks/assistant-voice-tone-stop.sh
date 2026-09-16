#!/bin/bash
# Assistant response voice-and-tone Stop hook.
# If docs/ASSISTANT-VOICE-AND-TONE.md exists, ask the same assistant for one
# semantic self-review continuation. The stop_hook_active guard prevents loops.

INPUT=$(cat)

[ -f "docs/ASSISTANT-VOICE-AND-TONE.md" ] || exit 0

STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

LAST_ASSISTANT_MESSAGE=$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null || echo "")
[ -n "$LAST_ASSISTANT_MESSAGE" ] || exit 0

jq -n --arg reason 'Review your previous response semantically against docs/ASSISTANT-VOICE-AND-TONE.md. If the response does not align, emit one complete corrected final response in the requested voice and tone. If no correction is needed, finish without adding user-facing commentary. Do not claim standards certification; claim alignment only when relevant.' '{
  decision: "block",
  reason: $reason
}'
