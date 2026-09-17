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

jq -n --arg reason 'Read docs/ASSISTANT-VOICE-AND-TONE.md and rewrite your previous response as one complete final response. Preserve its meaning, but make the voice requested by the guide unmistakable rather than merely acceptable. Always emit the complete replacement response, even when the previous response already aligns. Never return an empty response, a verdict, or review commentary. Do not claim standards certification; claim alignment only when relevant.' '{
  decision: "block",
  reason: $reason
}'
