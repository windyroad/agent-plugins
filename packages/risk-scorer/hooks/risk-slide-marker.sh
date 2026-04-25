#!/bin/bash
# Risk Scorer - PostToolUse:Agent|Bash slide-marker hook (P111).
# Slides the parent session's existing risk score files forward on
# subprocess return, treating subprocess wall-clock as continuous parent-
# session work for TTL purposes. Only TOUCHES existing score files — never
# creates one (creation requires a real risk-scorer:pipeline run that emits
# RISK_SCORES, parsed in risk-score-mark.sh).
#
# Score files that carry TTL semantics (Band A/B/C policy in risk-gate.sh):
#   ${RDIR}/commit, ${RDIR}/push, ${RDIR}/release.
#
# Files DELIBERATELY NOT slid:
#   - ${RDIR}/*-born — birth timestamps for the 2×TTL hard-cap (P090). The
#     hard-cap is meant to be invariant under sliding so an unchanged-but-
#     idle tree cannot ride a single score indefinitely (ADR-009 footnote
#     "Three-band TTL refinement"). Sliding the born marker would defeat
#     that protection.
#   - ${RDIR}/state-hash — drift-detection hash, not TTL-governed.
#   - ${RDIR}/{reducing,incident}-* — bypass markers, presence-only.
#   - ${RDIR}/{plan,wip,policy}-reviewed — presence-only review markers.
#
# See ADR-009 "Subprocess-boundary refresh" and P111 for context. Failed
# subprocesses (tool_response.is_error=true) do NOT extend the trust window
# — see slide_marker_on_subprocess_return in lib/gate-helpers.sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

_parse_input

SESSION_ID=$(_get_session_id)
[ -n "$SESSION_ID" ] || exit 0

RDIR=$(_risk_dir "$SESSION_ID")

slide_marker_on_subprocess_return "${RDIR}/commit"
slide_marker_on_subprocess_return "${RDIR}/push"
slide_marker_on_subprocess_return "${RDIR}/release"

exit 0
