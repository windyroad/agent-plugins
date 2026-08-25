#!/usr/bin/env bash
# wr-itil — predicate: is a ticket's closure explicitly blocked? (P519)
#
# Sibling of packages/architect/scripts/is-decision-unconfirmed.sh: answers ONE
# question for ONE ticket via its EXIT CODE, for the Verification Pending ->
# Closed guard in /wr-itil:transition-problem, /wr-itil:transition-problems,
# /wr-itil:manage-problem and /wr-itil:work-problems.
#
# Evidence-backed closure is agent-authorised (P519). This predicate is the
# machine-checkable half of the carve-out that keeps genuine ambiguity on the
# maintainer's surface: a ticket carrying an explicit DO-NOT-CLOSE marker keeps
# blocking closure even when the evidence would otherwise satisfy the ticket's
# own close criterion. Making the marker a field read rather than prose the
# next agent must happen to notice is what stops the carve-out eroding.
#
# Marker shape (LINE-ANCHORED, per the ADR-079 advisory-A2 lesson): the literal
# uppercase `DO NOT CLOSE` in a markdown heading line, or in a bold/bullet
# marker line. A mention inside a fenced code block or mid-prose is NOT a
# marker — that is how tickets *discuss* the mechanism, and treating discussion
# as a block would re-strand the queue this predicate exists to let drain.
#
# Usage:
#   is-close-blocked.sh <ticket-ref> [PROBLEMS_DIR]
#     <ticket-ref>  = P<NNN> | <NNN> | path/to/<NNN>-title.md
#     PROBLEMS_DIR  defaults to docs/problems
#
# Exit codes:
#   0 = BLOCKED — marker present. Prints the matching line on stdout.
#   1 = not blocked. No stdout.
#   2 = ticket not found / unreadable ref. No stdout; reason on stderr.
#
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution)
# @adr ADR-022 (Verifying lifecycle — the V->C transition this guards)
# @adr ADR-044 (framework-resolution boundary — the marker is the recorded
#               signal that routes a close back to the user's surface)
# @adr ADR-026 (agent output grounding)
# @problem P519 (evidence-backed closure is agent-authorised; ambiguity is not)

set -uo pipefail

REF="${1:-}"
PROBLEMS_DIR="${2:-docs/problems}"

if [ -z "$REF" ]; then
  echo "is-close-blocked: missing <ticket-ref>" >&2
  echo "usage: is-close-blocked.sh <ticket-ref> [PROBLEMS_DIR]" >&2
  exit 2
fi

# --- Resolve the ticket file -----------------------------------------------
file=""
if [ -f "$REF" ]; then
  file="$REF"
else
  id="${REF#[Pp]}"
  # Zero-pad a bare number to the three-digit ticket convention.
  case "$id" in
    ''|*[!0-9]*) : ;;
    *) id="$(printf '%03d' "$((10#$id))")" ;;
  esac
  # Dual-tolerant per RFC-002: per-state subdirs AND the flat legacy layout.
  for cand in \
    "$PROBLEMS_DIR"/*/"$id"-*.md \
    "$PROBLEMS_DIR"/"$id"-*.md
  do
    [ -f "$cand" ] || continue
    file="$cand"
    break
  done
fi

if [ -z "$file" ] || [ ! -r "$file" ]; then
  echo "is-close-blocked: no readable ticket for ref '$REF' under '$PROBLEMS_DIR'" >&2
  exit 2
fi

# --- Scan for the marker, skipping fenced code blocks ----------------------
match="$(awk '
  # Toggle fence state on ``` or ~~~ openers/closers.
  /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
  fenced { next }
  # Line-anchored: a heading, or a bold/bullet marker line.
  /^[[:space:]]*(#{1,6}[[:space:]]|[-*+][[:space:]]|\*\*)/ {
    if (index($0, "DO NOT CLOSE") > 0) { print; exit }
  }
' "$file")"

if [ -n "$match" ]; then
  printf '%s\n' "$match"
  exit 0
fi

exit 1
