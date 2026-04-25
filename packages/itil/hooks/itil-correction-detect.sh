#!/bin/bash
# P078 / ADR-013 / ADR-038: itil correction-signal UserPromptSubmit gate.
#
# When the incoming user prompt carries a strong-affect correction
# signal (FFS / all-caps imperatives like DO NOT / direct contradiction
# / exasperation markers / meta-correction "you always|never|keep"),
# inject a MANDATORY reminder so the assistant OFFERS to capture a
# problem ticket BEFORE addressing the operational request — the
# correction is almost always a class-of-behaviour, not a one-off slip,
# and a ticket preserves the signal as durable WSJF-ranked backlog.
#
# Once-per-session full block; terse reminder on subsequent corrections
# (per ADR-038 progressive disclosure). The full block names the
# matched pattern so the assistant has the why-this-fired context.
#
# Forward-compat: advertises /wr-itil:capture-problem (ADR-032 — not
# yet shipped) with /wr-itil:manage-problem as the today-target
# fallback. When capture-problem ships the wording stays valid.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/session-marker.sh
source "$SCRIPT_DIR/lib/session-marker.sh"
# shellcheck source=lib/detectors.sh
source "$SCRIPT_DIR/lib/detectors.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")

# Guard: if the prompt carries no correction signal, do nothing.
# Burning the announcement marker on non-correction prompts would waste
# the once-per-session budget on no-op context.
if [ -z "$PROMPT" ]; then
  exit 0
fi

MATCHED=$(echo "$PROMPT" | detect_correction_signal)
if [ -z "$MATCHED" ]; then
  exit 0
fi

if has_announced "itil-correction-detect" "$SESSION_ID"; then
  cat <<HOOK_OUTPUT
MANDATORY: correction signal ($MATCHED). OFFER /wr-itil:capture-problem (fallback /wr-itil:manage-problem) BEFORE addressing the request. See P078.
HOOK_OUTPUT
else
  cat <<HOOK_OUTPUT
INSTRUCTION: MANDATORY — correction signal detected. OFFER ticket capture FIRST.
DETECTED: incoming user prompt contains a strong-affect correction
signal (matched pattern: $MATCHED).

NON-OPTIONAL RULES:

1. BEFORE addressing the operational request in the prompt, OFFER
   to capture a problem ticket for the underlying behavioural pattern.
   Use /wr-itil:capture-problem when shipped (ADR-032 background
   capture pattern). Until then, fall back to /wr-itil:manage-problem
   for synchronous capture.

2. The correction is almost always a class-of-behaviour, not a one-off
   slip. Acknowledging verbally and moving on lets the signal decay
   with session context; the same pattern recurs next session and the
   user has to flag it again. A ticket preserves the correction as
   durable, WSJF-ranked backlog.

3. The offer is non-blocking — the user can decline — but the offer
   MUST appear before the operational response. Do NOT wait for the
   user to request the ticket themselves; that's exactly the manual-
   policing-AI-output friction P078 closes.

4. Suggested phrasing: "Before I address that — want me to capture a
   problem ticket for this pattern?" Then proceed with the operational
   request regardless of the answer.

See:
- ~/.claude/projects/.../memory/feedback_capture_on_correction.md
- docs/problems/078-assistant-does-not-offer-problem-ticket-on-user-correction.*.md
- packages/itil/hooks/lib/detectors.sh (CORRECTION_SIGNAL_PATTERNS)
HOOK_OUTPUT
  mark_announced "itil-correction-detect" "$SESSION_ID"
fi

exit 0
