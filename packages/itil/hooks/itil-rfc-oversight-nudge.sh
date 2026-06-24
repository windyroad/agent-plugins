#!/usr/bin/env bash
# wr-itil — SessionStart hook (P378/RFC-030; ADR-066/068 oversight-nudge clone)
#
# Surfaces a one-line nudge when RFCs lack the human-oversight marker, so the
# user can ratify them via /wr-itil:manage-rfc <RFC-NNN> (the accepted
# transition ratifies RFC scope). Sibling of architect-oversight-nudge.sh
# (ADR-066) and jtbd-oversight-nudge.sh (ADR-068); same class-B SessionStart
# shape as the ADR-040 session-start surface — so ratification is auto-surfaced
# every session instead of leaning on the user's memory (P378).
#
# Detection is token-cheap: delegates to detect-unoversighted-rfcs.sh (a grep
# over docs/rfcs/ frontmatter — no body reads, no per-RFC LLM call). Silent
# when the unoversighted count is zero (steady state once ratified).
#
# AFK self-suppress: shares the suite-wide WR_SUPPRESS_OVERSIGHT_NUDGE guard
# with the architect + jtbd oversight nudges (ADR-068 § shared cross-plugin
# contracts). AFK orchestrators export it once and every oversight nudge
# self-suppresses — so this interactive ratify nudge never fires into an
# absent-user subprocess (JTBD-006 friction guard). Only the literal "1"
# suppresses. Silent-on-zero; fail-open; ADR-040 ≤2KB budget (one line).

set -uo pipefail

if [ "${WR_SUPPRESS_OVERSIGHT_NUDGE:-}" = "1" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
RFCS_DIR="$PROJECT_DIR/docs/rfcs"

[ -d "$RFCS_DIR" ] || exit 0

DETECT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/scripts/detect-unoversighted-rfcs.sh"
[ -x "$DETECT" ] || DETECT="$(dirname "$0")/../scripts/detect-unoversighted-rfcs.sh"
[ -r "$DETECT" ] || exit 0

COUNT="$(bash "$DETECT" "$RFCS_DIR" 2>/dev/null | grep -c . || true)"
COUNT="${COUNT:-0}"

[ "$COUNT" -gt 0 ] 2>/dev/null || exit 0

if [ "$COUNT" -eq 1 ]; then
  echo "[wr-itil] 1 RFC lacks human oversight — run /wr-itil:manage-rfc <RFC-NNN> to ratify it (the accepted transition confirms scope)."
else
  echo "[wr-itil] $COUNT RFCs lack human oversight — run /wr-itil:manage-rfc <RFC-NNN> to ratify them (the accepted transition confirms scope)."
fi
