#!/bin/bash
# P085 / ADR-013 / ADR-038: itil UserPromptSubmit gate.
#
# When the incoming user prompt contains a direction-pinning signal
# (yes / go ahead / just do it / act now / proceed / ...), inject a
# MANDATORY reminder so the assistant acts instead of surfacing a
# prose consent gate. Once-per-session full block; terse reminder on
# subsequent direction-pin prompts.
#
# Companion: itil-assistant-output-review.sh (Stop hook) catches any
# prose-ask that slipped through on the way out.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/session-marker.sh
source "$SCRIPT_DIR/lib/session-marker.sh"
# shellcheck source=lib/detectors.sh
source "$SCRIPT_DIR/lib/detectors.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")

# Guard: if the prompt carries no direction-pinning signal, do nothing.
# Burning the announcement marker on non-direction prompts would waste
# the once-per-session budget on no-op context.
if [ -z "$PROMPT" ] || ! echo "$PROMPT" | detect_direction_pin >/dev/null; then
  exit 0
fi

if has_announced "itil-assistant-gate" "$SESSION_ID"; then
  cat <<'HOOK_OUTPUT'
MANDATORY: direction pinned. Act on obvious next step; use AskUserQuestion tool for genuine ambiguity; NEVER prose-ask. See ADR-013.
HOOK_OUTPUT
else
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY — act on obvious decisions; NEVER prose-ask.
DETECTED: incoming user prompt contains a direction-pinning signal
(yes / go / proceed / act / just do it / ...).

NON-OPTIONAL RULES:

1. If the next step is obvious from the user's direction, session
   context, or RISK-POLICY.md appetite, ACT. Do NOT surface a consent
   gate. Do NOT ask "Want me to...?" or "Should I...?".

2. If the decision is genuinely ambiguous (multiple-valid-paths, none
   clearly better per direction/policy), use the AskUserQuestion tool.
   Never prose-ask. Prose questions are unanswerable under AFK
   notifications and violate ADR-013 Rule 1.

3. Canonical prose-ask phrasings to AVOID in your next response:
   "Want me to", "Should I", "Would you like me to", "Shall we",
   "Let me know if", "Do you want to", "Option A or Option B?",
   "(a) / (b) / (c)?". If one of these is about to appear at the end
   of your turn, stop and re-route via AskUserQuestion or just act.

4. The combined rule: obvious default => act; genuine ambiguity =>
   AskUserQuestion tool; NEVER prose-ask.

See:
- ~/.claude/projects/.../memory/feedback_act_on_obvious_decisions.md
- docs/decisions/013-structured-user-interaction-for-governance-decisions.*.md
- Companion Stop hook (itil-assistant-output-review.sh) scans your
  emitted turn for the patterns above and nudges if any slip through.
HOOK_OUTPUT
  mark_announced "itil-assistant-gate" "$SESSION_ID"
fi

exit 0
