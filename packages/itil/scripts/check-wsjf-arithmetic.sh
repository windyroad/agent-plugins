#!/usr/bin/env bash
# packages/itil/scripts/check-wsjf-arithmetic.sh
#
# Diagnose-only WSJF arithmetic self-check. For every open / known-error
# problem ticket, recompute `(Severity × Status Multiplier) / Effort
# Divisor` from the ticket's OWN `**Priority**`, status and `**Effort**`
# fields and report any disagreement with its stored `**WSJF**` line.
#
# This closes the gap that `reconcile-readme.sh` cannot: that script
# compares ticket-ID-to-status MEMBERSHIP between README sections and
# the filesystem, and never parses a WSJF number. A value that is wrong
# in the ticket body AND wrong the same way in the README row is
# perfectly consistent, so membership reconciliation exits 0 clean. The
# observed failure mode (P477) is exactly that shape: WSJF is computed
# before the Open → Known Error auto-transition, nothing recomputes
# afterwards, and the ticket keeps the Open 1.0 multiplier at half its
# real rank in both places.
#
# Usage:
#   check-wsjf-arithmetic.sh [<problems-dir>]
#
# Default <problems-dir> is ./docs/problems.
#
# Exit codes:
#   0 = every parseable ticket's stored WSJF matches its own fields
#   1 = at least one mismatch (structured report to stdout)
#   2 = parse error (<problems-dir> missing)
#
# Output format on mismatch (one line per ticket, ≤ 150 bytes per
# ADR-038 progressive-disclosure budget):
#   WSJF <ID> arithmetic: stated=<x> computed=<y> sev=<n> status=<s> effort=<e>
#
# Tickets missing any of the three input fields are counted and
# summarised on stderr rather than reported as mismatches — an adopter
# upgrading into this check should not have their legacy corpus read as
# broken.
#
# Verification Pending and Parked tickets are NOT checked: ADR-022 gives
# them multiplier 0 and excludes them from the dev-work ranking, so
# there is no arithmetic to reconcile. The omission is deliberate.
#
# Read-only — does NOT mutate any ticket or README.
#
# DELIBERATELY NOT WIRED into `reconcile-readme.sh`, and not into any
# commit or preflight gate. `classify-readme-drift.sh` sweeps every
# `P<NNN>` token out of that script's stdout and routes uncovered IDs to
# `HALT_ROUTE_RECONCILE`, but `/wr-itil:reconcile-readme` is README-only
# and explicitly does not re-rate WSJF or edit ticket bodies — so an
# arithmetic finding surfaced there would dispatch to a remedy that
# cannot clear it, halting `manage-problem` on every invocation. This
# script is invoked from `/wr-itil:review-problems` Step 2, which is the
# documented owner of re-rating and can act on what it reports.
#
# @problem P477 (WSJF not recomputed on a status transition)
# @adr ADR-022 (Verification Pending / Parked carry multiplier 0)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-049 (Plugin-bundled scripts resolve via bin/ on $PATH)
# @adr ADR-052 (Behavioural tests by default)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-202 (Run Pre-Flight Governance Checks Before Release or Handover)

set -uo pipefail

PROBLEMS_DIR="${1:-docs/problems}"

if [ ! -d "$PROBLEMS_DIR" ]; then
  echo "PARSE_ERROR: problems dir not found at ${PROBLEMS_DIR}" >&2
  exit 2
fi

# Status multiplier per /wr-itil:manage-problem's WSJF table.
multiplier_for() {
  case "$1" in
    known-error) echo "2.0" ;;
    open)        echo "1.0" ;;
    *)           echo "" ;;
  esac
}

# Effort divisor per /wr-itil:manage-problem's Effort table.
divisor_for() {
  case "$1" in
    S)  echo 1 ;;
    M)  echo 2 ;;
    L)  echo 4 ;;
    XL) echo 8 ;;
    *)  echo "" ;;
  esac
}

MISMATCHES=()
skipped=0

check_ticket() {
  local file="$1" ticket_status="$2"
  local base num id severity effort stated mult div computed

  base="$(basename "$file")"
  num="${base%%-*}"
  id="P${num}"

  # `**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 ...` → 12
  severity="$(grep -m1 -oE '^\*\*Priority\*\*:[[:space:]]*[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+$')"
  # `**Effort**: M — derived at capture ...` → M
  effort="$(grep -m1 -oE '^\*\*Effort\*\*:[[:space:]]*(XL|S|M|L)\b' "$file" 2>/dev/null | grep -oE '(XL|S|M|L)$')"
  # `**WSJF**: 6.0 — (12 × 1.0) / 2` → 6.0
  stated="$(grep -m1 -oE '^\*\*WSJF\*\*:[[:space:]]*[0-9]+(\.[0-9]+)?' "$file" 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?$')"

  mult="$(multiplier_for "$ticket_status")"
  div="$(divisor_for "${effort:-}")"

  # A ticket missing any input is not a mismatch — it is unrateable here.
  if [ -z "$severity" ] || [ -z "$stated" ] || [ -z "$mult" ] || [ -z "$div" ]; then
    skipped=$((skipped + 1))
    return
  fi

  computed="$(awk -v s="$severity" -v m="$mult" -v d="$div" 'BEGIN { printf "%.10g", (s * m) / d }')"

  # Tolerance absorbs `6` vs `6.0` and one-decimal rounding in stored values.
  if awk -v a="$stated" -v b="$computed" 'BEGIN { exit ((a - b < 0.01) && (b - a < 0.01)) ? 0 : 1 }'; then
    return
  fi

  MISMATCHES+=("WSJF ${id} arithmetic: stated=${stated} computed=${computed} sev=${severity} status=${ticket_status} effort=${effort}")
}

shopt -s nullglob
# Flat layout: docs/problems/<NNN>-<title>.<state>.md
for f in "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.open.md; do
  check_ticket "$f" open
done
for f in "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.known-error.md; do
  check_ticket "$f" known-error
done
# Per-state subdir layout: docs/problems/<state>/<NNN>-<title>.md (ADR-031).
# Both halves are walked per the RFC-002 dual-tolerant migration window.
for ticket_status in open known-error; do
  for f in "$PROBLEMS_DIR"/"$ticket_status"/[0-9][0-9][0-9]-*.md; do
    check_ticket "$f" "$ticket_status"
  done
done
shopt -u nullglob

if [ "$skipped" -gt 0 ]; then
  echo "note: ${skipped} ticket(s) skipped — missing Priority, Effort or WSJF field" >&2
fi

if [ ${#MISMATCHES[@]} -eq 0 ]; then
  exit 0
fi

IFS=$'\n' sorted=($(printf '%s\n' "${MISMATCHES[@]}" | sort))
unset IFS
for line in "${sorted[@]}"; do
  printf '%s\n' "$line"
done
exit 1
