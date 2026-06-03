#!/usr/bin/env bash
# wr-itil — predicate: are the JTBDs cited by a problem ticket all ratified?
# (RFC-016 / P344 — orchestrator-layer mirror of ADR-068 surface 3)
#
# `/wr-itil:work-problems` Step 3.5 invokes this script on the selected
# ticket BEFORE dispatching the iter-subprocess. The per-iter JTBD review
# subagent already catches the same class via the [Unratified Dependency]
# verdict (ADR-068 surface 3), but only AFTER spending iter-dispatch cost.
# This script shifts the predicate left to the orchestrator layer for the
# cost of one grep + one shim call per cited JTBD.
#
# Polarity (RFC-016 § Scope — outer-script polarity INVERTED vs the inner
# per-JTBD predicate it dispatches):
#   exit 0 = all cited JTBDs ratified OR ticket cites none → orchestrator
#            proceeds with the dispatch. No stdout.
#   exit 1 = ≥1 cited JTBD unratified → orchestrator routes to Step 4
#            user-answerable skip + queues outstanding_question.
#            One ID per stdout line; `JTBD-NNN (unresolved)` for IDs whose
#            per-JTBD predicate returned exit 2 (no matching file).
#   exit 2 = ticket file missing / unreadable. No stdout; reason on stderr.
#
# Silent-pass on missing per-JTBD shim: when `wr-jtbd-is-job-or-persona-
# unconfirmed` is not on PATH (degenerate adopter case per ADR-031 —
# adopter installed @windyroad/itil without @windyroad/jtbd), the script
# silent-passes (exit 0). The iter-subprocess JTBD subagent is the
# authoritative second-source; orchestrator-layer pre-check is optimisation.
#
# Usage:
#   check-ticket-jtbd-ratification.sh <ticket-file> [JTBD_DIR]
#     <ticket-file> = path to a problem-ticket .md file (relative or absolute)
#     JTBD_DIR defaults to docs/jtbd
#
# @rfc RFC-016 (P344 — work-problems Step 3.5 JTBD ratification predicate)
# @adr ADR-068 (JTBD + persona human-oversight marker — surface 3 mirrored)
# @adr ADR-074 (substance-confirm-before-build — JTBD-as-driver symmetric)
# @adr ADR-049 (PATH shim grammar)
# @problem P344

set -uo pipefail

TICKET="${1:-}"
JTBD_DIR="${2:-docs/jtbd}"

[ -n "$TICKET" ] || {
  echo "check-ticket-jtbd-ratification: missing <ticket-file>" >&2
  exit 2
}

[ -f "$TICKET" ] || {
  echo "check-ticket-jtbd-ratification: no such ticket file: $TICKET" >&2
  exit 2
}

# ADR-031 silent-pass: if the per-JTBD predicate shim is absent, the
# orchestrator-layer pre-check cannot run. The iter-subprocess JTBD
# subagent will catch any unratified-dep at the inner layer; this script
# is the optimisation surface, not the authoritative gate.
if ! command -v wr-jtbd-is-job-or-persona-unconfirmed >/dev/null 2>&1; then
  exit 0
fi

# Extract cited JTBD IDs from the ticket body. Match `JTBD-NNN` (with or
# without leading zero) — the canonical citation form across Decision
# Drivers / **JTBD**: frontmatter / **Persona**: references. Dedupe so
# the same JTBD cited multiple times only runs the predicate once.
cited="$(grep -oE 'JTBD-[0-9]+' "$TICKET" 2>/dev/null | sort -u || true)"

[ -n "$cited" ] || exit 0   # vacuous-pass: no JTBDs cited at all

unratified=""
while IFS= read -r jtbd_id; do
  [ -n "$jtbd_id" ] || continue
  # Call the inner per-JTBD predicate. INNER POLARITY:
  #   inner exit 0 = unconfirmed (build-upon guard SHOULD fire) → unratified
  #   inner exit 1 = confirmed or superseded → ratified
  #   inner exit 2 = not found / unparseable ref → unresolved
  wr-jtbd-is-job-or-persona-unconfirmed "$jtbd_id" "$JTBD_DIR" >/dev/null 2>&1
  inner_status=$?
  case $inner_status in
    0) unratified="${unratified}${jtbd_id}"$'\n' ;;
    1) ;;   # ratified — silent
    2) unratified="${unratified}${jtbd_id} (unresolved)"$'\n' ;;
    *) unratified="${unratified}${jtbd_id} (predicate error: exit ${inner_status})"$'\n' ;;
  esac
done <<< "$cited"

if [ -n "$unratified" ]; then
  printf '%s' "$unratified"
  exit 1
fi

exit 0
