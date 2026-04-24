#!/bin/bash
# P085 / ADR-013: itil Stop hook.
#
# Reads the last assistant turn from transcript_path on stdin and scans
# for canonical prose-ask phrasings. If a prose-ask is detected (and
# the turn does NOT contain an AskUserQuestion tool_use call), emits
# a stopReason nudge instructing the assistant to re-emit via
# AskUserQuestion — or act, if the decision was obvious.
#
# Stop hooks cannot rewrite the emitted turn; the nudge biases the
# next turn. Pairs with UserPromptSubmit gate for defence in depth.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/detectors.sh
source "$SCRIPT_DIR/lib/detectors.sh"

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

# Graceful fallback: no transcript_path or file missing means nothing
# to review. Exit clean — the hook is advisory, never blocking.
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Extract the last assistant turn's concatenated text content. Claude
# Code transcript format: JSONL, each line a {type, message} object;
# assistant `message.content` is an array of content blocks (text,
# tool_use, thinking, ...). We want the concatenation of `text` blocks
# from the last `type: assistant` line.
LAST_ASSISTANT=$(grep -E '"type"[[:space:]]*:[[:space:]]*"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -n 1 || true)
if [ -z "$LAST_ASSISTANT" ]; then
  exit 0
fi

# If the last assistant turn used AskUserQuestion, the assistant chose
# the structured path — don't nudge.
if echo "$LAST_ASSISTANT" | jq -e '.message.content | map(select(.type == "tool_use" and .name == "AskUserQuestion")) | length > 0' >/dev/null 2>&1; then
  exit 0
fi

# Concatenate every text block in the turn.
ASSISTANT_TEXT=$(echo "$LAST_ASSISTANT" | jq -r '
  .message.content
  | if type == "array" then map(select(.type == "text") | .text) | join("\n")
    elif type == "string" then .
    else "" end
' 2>/dev/null || echo "")

if [ -z "$ASSISTANT_TEXT" ]; then
  exit 0
fi

# Scan for prose-ask patterns. If none match, exit silently.
MATCH=$(echo "$ASSISTANT_TEXT" | detect_prose_ask 2>/dev/null) || true
if [ -z "$MATCH" ]; then
  exit 0
fi

# Emit stopReason. Structured JSON so Claude Code injects the nudge
# into the next assistant context. The user does not see this — the
# next turn does.
jq -n --arg match "$MATCH" '{
  stopReason: (
    "PROSE-ASK DETECTED in your last turn (pattern: \"" + $match + "\"). " +
    "If the decision is obvious from direction / policy / session context, ACT — do not ask. " +
    "If genuinely ambiguous, re-emit via the AskUserQuestion tool. " +
    "Never prose-ask. See ADR-013 Rule 1 + feedback_act_on_obvious_decisions.md."
  )
}'

exit 0
